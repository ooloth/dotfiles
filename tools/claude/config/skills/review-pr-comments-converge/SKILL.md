---
name: review-pr-comments-converge
description: Fetch PR review comments, validate each against the actual code, auto-fix obvious issues, and escalate genuine design decisions. Leaves all changes in the working tree. Use when you want to action reviewer feedback autonomously.
argument-hint: '<pr-number>'
effort: high
model: opus
---

## Role

Act as a coordinator. You spawn subagents to validate and fix; your job is to route their output,
track state across rounds, emit progress, and decide when to stop.

**Never commit.** All changes land in the working tree for the user to review and commit.

---

## Phase 0: Parse Arguments

Read the PR number from `$ARGUMENTS`. If missing, ask:

> "Which PR number should I process comments for?"

Once clear, emit:

```
PR: [number]
Starting review-pr-comments-converge...
```

---

## Helper Scripts

Two scripts live in `scripts/` relative to this skill's base directory (shown at the top of this
skill's content as "Base directory for this skill: ..."). Use them throughout the run.

### `scripts/fetch_pr_comments.py <pr-number>`

Fetches all inline comments and review body comments via the GitHub GraphQL API. Each inline
comment in the output includes:

- **`comment_id`** — the integer ID needed to post a reply
- **`thread_id`** — the node ID needed to resolve the conversation thread
- **`File:`** — the file path repeated immediately before the diff hunk

### `scripts/reply_to_comment.py <pr-number> <comment-id> <body> [--resolve]`

Posts a reply to an inline comment. Pass `--resolve` to also close the conversation thread.
The thread ID is looked up automatically from the comment ID — you only need to pass the
`comment_id` shown in `fetch_pr_comments.py` output.

```bash
uv run <skill-base-dir>/scripts/reply_to_comment.py 196 3126400199 "Fixed — changed to 'fill empty snapshots'." --resolve
```

> **Note:** `reply_to_comment.py` handles inline review comments only. Review body comments
> (the `=== Review Body Comments ===` section) show a `review_id` for reference but are not
> replyable via this script — respond to them with `gh pr comment <pr-number> --body "..."`.

---

## Phase 1: Fetch Comments & Load Context

**Fetch all PR comments** by running the fetch helper:

```bash
uv run <skill-base-dir>/scripts/fetch_pr_comments.py <pr-number>
```

Also fetch the PR description for context on intent:

```bash
gh pr view <pr-number> --json title,body,baseRefName
```

Discover the **quality gate**: check `CLAUDE.md` and project docs for the standard lint/type/test
commands. Record whatever you find. If nothing is documented, note it and skip the quality gate
step each round.

Distill a short **problem statement** from the PR title and description: what pain point or goal
do these changes address? If unclear, note "intent unclear" — do not invent one.

---

## Phase 2: Validate & Converge

Maintain a **decided list** across all rounds: every comment that has been resolved (auto-fixed,
escalated, or dismissed) in a prior round. Never re-present a decided item.

Run up to **3 rounds**. Before each round, emit:

```
Round N/3: validating...
```

### Step A — Validate Comments (subagent)

Spawn a general-purpose subagent. Pass it:

- The full list of comments from Phase 1 (minus any already on the decided list)
- The problem statement and PR description
- Instruction to read the relevant code at each commented location (and surrounding context) to
  independently verify whether each comment is correct, stale, or mistaken — **do not trust
  comments at face value**
- Instruction to return one verdict per comment:
  - **Valid** — the comment identifies a real issue; include the issue and a suggested fix
  - **Stale** — the code has already been changed to address this; include evidence
  - **Mistaken** — the comment is wrong; include why

Wait for the subagent to return verdicts.

### Step B — Classify Valid Findings

Ignore Stale and Mistaken comments (add to decided list; they appear in the report as Dismissed).

Partition Valid findings:

**Auto-fix** — there is one clearly correct answer:

- Obvious correctness fixes (bugs, wording contradictions, unquoted variables, etc.)
- Consistency fixes with no ambiguity (matching the pattern used everywhere else)
- The mechanical part of a mixed finding — see splitting rule below

The test: *does applying this require the author to make a choice?* If no, auto-fix it.

**Escalate** — the right answer depends on a decision only the author can make:

- Multiple valid approaches exist and the choice depends on requirements or preferences
- The fix would change a public API, data model, or contract
- Correctly fixing it requires intent or context only the author has

**Escalation discipline:**

- Resolve all analytical sub-questions yourself by reading the code. Never escalate "is this a
  bug?" — answer it yourself. Only escalate the *decision*.
- Every escalation must present ≥2 concrete lettered options with outcomes. Mark your recommended
  option `(recommended)`.

**Splitting rule:** If a comment contains both a mechanical sub-fix and a design question, apply
the mechanical sub-fix and escalate only the design question.

Add all classified findings to the decided list.

### Step C — Check for Repetition

If the same location appeared in a prior round after a fix attempt, escalate instead of retrying.

### Step D — Decide Whether to Continue

Emit:

```
Round N/3: [X] auto-fix, [Y] escalate, [Z] dismissed (stale/mistaken), [W] repeated
```

- If **no auto-fix findings**: exit the loop
- If **round limit reached**: exit the loop
- Otherwise: continue to Step E

### Step E — Fix (subagents, parallel where safe)

Verify file paths exist before spawning. Group findings by file; spawn one fix subagent per file
(or small related group) in parallel. Pass each:

- Its subset of auto-fix findings with suggested fixes
- The relevant file paths
- Instruction: implement every finding exactly as described; no additional changes; no commits

Wait for all fix subagents to complete.

**Run the quality gate.** Feed any new failures back into the next round as additional findings.

Emit:

```
Round N/3: applied [X] fixes[, quality gate: OK | N new issues]
```

Record what was changed (file, issue, fix applied, before/after snippet) for the report.

Return to the top of the loop.

---

## Phase 3: Report

Emit the full report in the conversation. Never abbreviate — every escalation with its complete
option list must appear. Do not write to disk.

**Stop here.** Do not post any GitHub replies or resolve any threads. Wait for the user to review
the working tree changes and explicitly approve posting replies (e.g. "post the replies", "reply
and resolve"). The report is the deliverable for this phase.

```markdown
# review-pr-comments-converge report

**PR:** [number] — [title]
**Rounds completed:** N of 3
**Outcome:** [Clean | Escalations remaining | Repetitions unresolved | Round limit reached]

---

## Changes made

Leave a blank line before and after every diff block.

### Round 1

- `file:line` — [reviewer] — [issue] — [fix applied]

  ```diff
  - [before, max 3 lines]
  + [after, max 3 lines]
  ```

### Round N
Clean — no auto-fixable findings.

---

## Dismissed comments

Comments that were stale or mistaken — no action taken.

- [reviewer] @ `file:line` — [Stale | Mistaken] — [reason]

(None)

---

## Escalated items

These require a decision from you. Reply with your decisions (e.g. "1b, 2a") and I'll apply them.

1. [reviewer] @ `file:line` — [issue] — Why escalated: [reason]
   - (a) [option] (recommended)
   - (b) [option]

(None)

---

## Working tree
All changes are uncommitted. Run `git diff` to review before committing.
[N total files modified]
```

---

## Phase 4: Post Replies (only after explicit user approval)

After the user has reviewed the working tree changes and explicitly approves (e.g. "post the
replies"), post replies and resolve threads:

- For each auto-fixed or dismissed comment with an inline `comment_id`: run
  `reply_to_comment.py` with `--resolve`
- For each escalated comment: post a reply summarising the options; do not resolve the thread
- Review body comments (no `comment_id`): respond with `gh pr comment`

Do not run any of these commands before receiving explicit approval in Phase 3.

### Reply tone

These replies go out as the PR author to their teammates. Write as a thoughtful colleague, not
an automated system:

- **Acknowledge the feedback specifically** — reference what they pointed out, not a generic
  "thanks for the feedback"
- **State what you did** (for fixes) or **present the decision clearly** (for escalations) —
  "Changed X to Y because Z" not "Fixed."
- **Be direct but not terse** — one or two sentences is usually right; never a single word
- **No bot-speak** — avoid "I have addressed your comment", "As per your request", "LGTM",
  or any phrase that reads as automated
- **For dismissals (stale/mistaken)**: explain briefly why no change was made — "This was
  already handled in the previous commit at file:line" or "I think this is intentional
  because X — happy to discuss if you see it differently"

---

## Guardrails

- **Max 3 rounds** — always. Never loop indefinitely.
- **No commits** — ever. Working tree only.
- **No scope creep** — only address findings derived from PR comments. Do not refactor or improve
  things outside the reported findings.
- **No silent changes** — every change must appear in the report with a diff snippet.
- **One attempt per issue** — if a fix doesn't hold, escalate immediately.
- **Split, don't bundle** — never hold a mechanical fix hostage to an unresolved design question.
- **Validate before fixing** — never auto-fix a comment without first confirming the comment is
  correct by reading the actual code.
