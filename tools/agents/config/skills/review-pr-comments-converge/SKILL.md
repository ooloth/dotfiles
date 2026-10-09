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

Three scripts live in `scripts/` relative to this skill's base directory (shown at the top of this
skill's content as "Base directory for this skill: ..."). Use them throughout the run.

**Call them by absolute path from the target repo's root — never `cd` into `scripts/` first.**
All three infer the repository from `$GH_REPO` or the working directory, so running them from the
skill's own directory targets the *dotfiles* repo instead. That does not fail loudly: PR numbers
are small and collide across repositories, so the wrong target is a real repo with a real PR of
the same number, and a reply meant for one project lands on another. Pass `--repo OWNER/NAME`
whenever the working directory is not the target. All three print the repo they resolved —
check that line before trusting the output or the write.

### `scripts/resolve_pr_checkout.py <pr-number> [--repo OWNER/NAME]`

Prints the directory to work in, a checkout of the PR's head branch, or exits 1 with the reason it
is unsafe to proceed. It uses a worktree whose branch is named after the head branch or tracks it,
or switches the current checkout to it when nothing would be lost, and refuses when the PR is
closed or on a fork, when the branch is behind or diverged from the remote, when two other
worktrees both hold it, or when another checkout's uncommitted changes are in the way. After a
switch it prints the command that undoes it. The script's docstring has the full rules.

### `scripts/fetch_pr_comments.py <pr-number>`

Fetches all inline comments, review body comments and PR conversation comments via the GitHub
GraphQL API. Conversation comments are the PR timeline, where some review bots post their whole
review; they appear last, oldest first. Each inline comment in the output includes:

- **`comment_id`** — the integer ID needed to post a reply
- **`thread_id`** — the node ID needed to resolve the conversation thread
- **`path:line`** — on the `COMMENT` header line, the file and line the comment is attached to

### `scripts/reply_to_comment.py <pr-number> <comment-id> <body> [--resolve] [--repo OWNER/NAME]`

Posts a reply to an inline comment. Pass `--resolve` to also close the conversation thread.
The thread ID is looked up automatically from the comment ID — you only need to pass the
`comment_id` shown in `fetch_pr_comments.py` output.

```bash
uv run <skill-base-dir>/scripts/reply_to_comment.py 196 3126400199 "Fixed — changed to 'fill empty snapshots'." --resolve
```

It prints `Target: OWNER/NAME#PR, comment ID` before writing. Read that line — it is the only
thing standing between a misresolved repo and a reply posted on a stranger's pull request.

> **Note:** `reply_to_comment.py` handles inline review comments only. Review bodies (the
> `OVERVIEW:` under each review, which shows a `review_id` for reference) and conversation
> comments (the `# PR CONVERSATION COMMENTS` section) are not replyable via this script —
> respond to them with `gh pr comment <pr-number> --body-file <path>`.

---

## Phase 1: Fetch Comments & Load Context

**Get onto the PR's head branch** by running the checkout helper from the session's working
directory:

```bash
uv run <skill-base-dir>/scripts/resolve_pr_checkout.py <pr-number>
```

On exit 0, the last line of stdout is the **working root**. Run every later command from it, pass
it to every subagent as the absolute path to read and edit in, and tell the user which path it is
and whether the helper switched a branch, with the undo command it printed. Do not ask first: the
helper only acts when nothing can be lost.

On exit 1, stop before Phase 2. Relay the helper's reason to the user and ask how to proceed. Do
not work around the refusal by switching branches yourself.

**Fetch all PR comments** by running the fetch helper from the working root:

```bash
uv run <skill-base-dir>/scripts/fetch_pr_comments.py <pr-number>
```

Also fetch the PR description for context on intent:

```bash
gh pr view <pr-number> --json title,body,baseRefName,headRefName
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

Spawn a general-purpose subagent. Set the Agent tool call's `model` parameter to `"sonnet"`. Pass
it:

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

- Resolve all analytical sub-questions yourself by reading the code, or by a read-only query
  (`gh api` GETs, ticket reads, another repo's config) when the answer lives outside the repo.
  These need no approval. Never escalate "is this a bug?" — answer it yourself. Only escalate the
  *decision*.
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

### Step E — Fix (one subagent per round)

Verify file paths exist before spawning. **Spawn one fix subagent for the whole round**, carrying
every auto-fix finding from this round. Set the Agent tool call's `model` parameter to `"sonnet"`.

One agent, not one per file. Fixes within a round depend on each other — a test has to be written
against the source fix it guards — so splitting by file produces a serial chain of handoffs that
looks like parallelism and isn't. One agent holds the whole round's context, and there is no
window in which two agents restore the same file.

Pass it:

- Every auto-fix finding from this round, with suggested fixes
- The relevant file paths
- Instruction: implement every finding exactly as described; no additional changes; no commits
- Instruction: run only what proves your own changes. Do not run the full quality gate — the
  coordinator runs it once after you return, and running it twice wastes a minute per round.

**Verification is proportional to what the fix changes.** A fix that alters runtime behaviour —
control flow, an exit code, a condition, an error path — is worth proving: revert it, confirm the
relevant test fails on the assertion that names the behaviour, then restore. A fix that cannot
change behaviour — formatting, a docstring, a comment, an import reorder — needs nothing beyond
the coordinator's quality gate.

**When mutating a file to prove a test, defeat stale bytecode.** A restored file can still be
imported from a cached compile of the mutated source: a same-second restore leaves the cached
artefact looking current, so the source is provably correct by checksum while the running code is
not. This has already produced one false test failure in a past run. Run every verification pass
with compilation caching off (`PYTHONDONTWRITEBYTECODE=1` for Python, the equivalent elsewhere),
and confirm the restore with both a checksum and a clean run, never the checksum alone.

Wait for the fix subagent to complete.

**Run the quality gate, once, yourself.** This is the coordinator's job and the fix subagent was
told not to do it, so this is the only place it runs each round. Feed any new failures back into
the next round as additional findings.

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

````markdown
# review-pr-comments-converge report

**PR:** [number] — [title]
**Rounds completed:** N of 3
**Outcome:** [Clean | Escalations remaining | Repetitions unresolved | Round limit reached]

---

## ✅ Changes made

Leave a blank line before and after every diff block.

### Round 1

- ✅ `file:line` — [reviewer] — [issue] — [fix applied]

  ```diff
  - [before, max 3 lines]
  + [after, max 3 lines]
  ```

### Round N
Clean — no auto-fixable findings.

---

## ❌ Dismissed comments

Comments that were stale or mistaken — no action taken.

- ❌ [reviewer] @ `file:line` — [Stale | Mistaken] — [reason]

(None)

---

## 💬 Escalated items

These require a decision from you. Reply with your decisions (e.g. "1b, 2a") and I'll apply them.

1. 💬 [reviewer] @ `file:line` — [issue] — Why escalated: [reason]
   - (a) [option] (recommended)
   - (b) [option]

(None)

---

## Working tree
All changes are uncommitted. Run `git diff` to review before committing.
[N total files modified]
````

---

## Phase 4: Post Replies (only after explicit user approval)

After the user has reviewed the working tree changes and explicitly approves (e.g. "post the
replies"), post replies and resolve threads:

- For each auto-fixed or dismissed comment with an inline `comment_id`: run
  `reply_to_comment.py` with `--resolve`
- For each escalated comment: post a reply summarising the options; do not resolve the thread
- Review body comments (no `comment_id`) and conversation comments: respond with `gh pr comment`

Do not run any of these commands before receiving explicit approval in Phase 3.

### Reply shape

A reviewer should be able to read the whole reply in 10 seconds. Each finding gets one line, and
that line opens with its verdict:

- ✅ fixed: say what changed, in a few words, then the short hash of the pushed commit in parens,
  e.g. `(2611d9d)`
- ❌ no change: give the reason in one clause, with a `file:line` or a quote as evidence
- 💬 needs your decision: list the lettered options; leave the thread open

For an inline reply, the body is that one line. For a review body or conversation comment that
covered several findings, write one bullet per finding, in the reviewer's order, and bold a short
label naming each finding so the reviewer can match it to their comment. Don't add a legend, a
summary paragraph, or the reviewer's point repeated back to them.

A ✅ line cites a commit, so the fix is committed and pushed before the reply is posted. A reply
claiming a fix the reviewer can't see on the PR is false until it is. When the working root's branch
is named differently from the head branch it tracks, a plain `git push` is refused under git's
default `push.default=simple`, so the push names both: `git push <remote> <local>:<head-branch>`.

### Reply tone

These replies go out as the PR author to their teammates. Write as a colleague would:

- **Name the specific point**, not "thanks for the feedback"
- **No bot-speak**: avoid "I have addressed your comment", "As per your request", "LGTM"
- **For ❌, give the reason without arguing**: "already handled at file:line", or "I think this is
  intentional because X"

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
- **One fix agent per round** — it holds the whole round's fixes. Never one per file.
- **The coordinator owns the quality gate** — it runs once per round, after the fix agent returns.
  The fix agent runs only what proves its own change.
- **Proportional proof** — prove a fix that changes runtime behaviour, and defeat compilation
  caching when you do. Formatting and docs need only the quality gate.
