---
name: review-converge
description: Autonomously review and fix the current branch or specified scope in iterative rounds until clean, leaving all changes in the working tree. Escalates only genuine design decisions. Ends with a transparent report of every round, every fix, and anything it couldn't resolve — persisted to .agents/.
argument-hint: '[branch name | PR number | file path | "current branch"]'
effort: high
model: opus
---

## Role

Act as a coordinator. You spawn subagents to do analysis and implementation work; your job is to
route their output, track state across rounds, emit progress, and decide when to stop.

**Never commit.** All changes land in the working tree for the user to review and commit using
their normal workflow.

---

## Phase 0: Clarify Scope

Read the scope from `$ARGUMENTS`.

If missing or ambiguous, ask:

> "What should I review? (e.g. `current branch`, a branch name, a PR number, or a file path)"

Wait for the user's response before continuing.

Once scope is clear, emit:

```
Scope: [resolved scope]
Starting review-converge (max 5 rounds)...
```

---

## Phase 1: Load Context

Before the first round, understand the intent of the changes:

- If scope is a **branch**: run `git log main..HEAD --oneline` and read the PR description if one
  exists (`gh pr view` — skip if no PR yet)
- If scope is a **PR number**: fetch the PR description with `gh pr view <number>`
- If scope is a **file path**: read the file and any related context files

Also discover what quality checks this project has documented. Look for:

- Commands mentioned in `CLAUDE.md` or project docs as the standard check/lint/test commands
- Scripts in `Makefile`, `package.json` (`lint`, `typecheck`, `test`), `pyproject.toml`, etc.
- Any CI configuration that reveals what checks run on every commit

Record whatever you find as the **quality gate** for this project. If nothing is documented,
note that and skip the quality gate step each round.

From what you read, distill a short **problem statement**: in 1-2 sentences, what pain point
or goal do these changes address, and what outcome should they achieve? If the git log and PR
description don't make this clear, note it as "intent unclear" — do not invent one.

The problem statement and quality gate are both passed to every subagent throughout the run.

---

## Phase 2: Converge Loop

Maintain a **decided list** across all rounds: every finding that has been auto-fixed or
escalated in a prior round. Before classifying findings each round, filter out anything already
on the decided list. This keeps review agents fresh and unbiased (they see everything anew) while
preventing the coordinator from re-presenting already-handled items.

Run up to **5 rounds**. Before each round, emit:

```
Round N/5: reviewing...
```

### Step A — Review

Invoke the `review-code` skill directly in the main conversation (via the Skill tool, not the Agent
tool). Skip `review-code`'s Steps 1 and 2 — scope, diff command, and intent are already established
in Phase 1 and do not change between rounds. Jump straight to Step 3, supplying:

- The diff command from Phase 1
- The reviewable file list from Phase 1
- The problem statement from Phase 1 as the intent block

Wait for `review-code` to return its merged findings in the standard format: Praise / Issues
(Critical, Important, Minor) / Questions / Patterns Observed.

### Step B — Classify Findings

Filter out any finding already on the decided list. Then partition remaining Issue findings:

**Auto-fix** — there is one clearly correct answer. This includes:

- Obvious correctness fixes (bugs, missing error handling, unquoted variables, etc.)
- Consistency fixes with no ambiguity (matching the pattern used everywhere else)
- Conservative improvements on working code (defensive quoting, minor style alignment)
- The mechanical part of a mixed finding — see splitting rule below

The test is: _does applying this require the author to make a choice?_ If no, auto-fix it.

**Escalate** — the right answer genuinely depends on a decision only the author can make:

- Multiple valid approaches exist and the choice depends on requirements or preferences
- The fix would change a public API, data model, or contract
- Correctly fixing it requires intent or context only the author has

Note: severity and escalation status are independent. A Critical finding with an obvious correct
fix is **auto-fix**. A Minor finding with two reasonable approaches is **escalate**.

**Escalation discipline** — before writing an escalation:

- Resolve all analytical sub-questions yourself by reading the code and tests. Never escalate
  "is this a bug?", "is this intentional?", or "does X occur in production?" — answer those
  yourself and state your conclusion. Only the _decision_ goes to the author.
- Every escalated item must present ≥2 concrete lettered action options, each with a clear
  outcome. If you find yourself writing an option like "(a) No action — just confirming
  awareness", the item is not a genuine escalation; move it to Patterns Observed instead.
- Mark your recommended option `(recommended)`.

**Splitting rule:** If a finding contains both a mechanical sub-fix and a design sub-question,
apply the mechanical sub-fix and escalate only the design question. Never hold a mechanical fix
hostage to an unresolved design question.

Add all classified findings to the decided list.

### Step C — Check for Repetition

Compare this round's auto-fix findings against prior rounds. A finding is **repeated** if the
same issue at the same location appeared in a prior round after a fix was attempted.

**One failed attempt = escalate.** Move it to the escalate bucket and add it to the decided list.

### Step D — Decide Whether to Continue

Emit one of:

```
Round N/5: [X] auto-fix, [Y] escalate, [Z] repeated
```

Then:

- If there are **no auto-fix findings**: exit the loop
- If the **round limit is reached**: exit the loop
- Otherwise: continue to Step E

### Step E — Fix (subagents, parallel where safe)

Before spawning fix subagents, verify any file paths referenced in the findings actually exist
(`ls` or `fd`). Correct a wrong path before passing it; if the right path is ambiguous, escalate.

**Group findings by file.** Spawn one fix subagent per file (or small group of related files)
in parallel using multiple Agent tool calls in a single message. Pass each subagent:

- Its subset of auto-fix findings with suggested fixes
- The relevant file paths and context
- Instruction: implement every finding exactly as described; do not make additional changes; do
  not commit anything

Wait for all fix subagents to complete.

**Run the quality gate.** If a quality gate was discovered in Phase 1, run it now. Feed any new
failures back into the next round as additional findings (do not auto-fix them here — let the
review loop handle them cleanly).

Emit:

```
Round N/5: applied [X] fixes[, quality gate: OK | N new issues]
```

Record what was changed (file, issue, fix applied, before/after snippet) for the report.

Then return to the top of the loop for the next round.

---

## Phase 3: Report

Once the loop exits, emit the full report in the conversation. **Never abbreviate it — the full
report, including every escalation with its complete lettered option list, must appear in the
conversation.** Do not produce a condensed summary. Do not write to disk.

Report format:

````markdown
# review-converge report

**Scope:** [resolved scope]
**Rounds completed:** N of 5
**Outcome:** [Clean | Escalations remaining | Repetitions unresolved | Round limit reached]

---

## Changes made

Leave a blank line before and after every diff block so items don't run together.

### Round 1

- `file:line` — [issue] — [fix applied]

  ```diff
  - [before, max 3 lines]
  + [after, max 3 lines]
  ```
````

- `file:line` — [issue] — [fix applied]

  ```diff
  - [before]
  + [after]
  ```

### Round 2

...

### Round N

Clean — no auto-fixable findings.

---

## Repeated findings (could not resolve)

These issues reappeared after a fix attempt. One attempt was made; escalating rather than
speculating further.

- `file:line` — [issue] — Attempted: [what was tried] — Why it didn't hold: [best guess]

(None)

---

## Escalated items

These require a decision from you. Each lists the options; add a confidence parenthetical on any
option where you have a strong lean (e.g. `(high confidence)`).

Reply with your decisions (e.g. "1b, 2a") and I'll apply them and do one final pass.

1. `file:line` — [issue] — Why escalated: [reason]
   - (a) [option] (high confidence)
   - (b) [option]
   - (c) [option if applicable]

2. `file:line` — [issue] — Why escalated: [reason]
   - (a) [option]
   - (b) [option]

(None)

---

## Documentation gaps

Patterns seen during this run that suggest missing or incomplete project documentation. Addressing
these would turn future escalations into auto-fixes and prevent the same issues from recurring.

- **[Pattern name]** — [what kept coming up] — Suggested addition: [which file to update and
  what to document, e.g. "add a note to conventions/bash.md that all helper functions must use
  the call-site failure pattern: `check_X ... || failures=$((failures + 1))`"]

(None)

---

## Working tree

All changes are uncommitted. Run `git diff` to review before committing.
[N total files modified]

---

## Guardrails

- **Max 5 rounds** — always. Never loop indefinitely.
- **No commits** — ever. Working tree only.
- **No scope creep** — only fix findings from the review. Do not refactor, clean up, or improve
  things outside the reported findings.
- **No silent changes** — every change made must appear in the report with a diff snippet.
- **One attempt per issue** — if a fix doesn't hold, escalate immediately rather than speculating.
- **Split, don't bundle** — never hold a mechanical fix hostage to an unresolved design question.
- **Decided list** — never re-present a finding the coordinator has already classified.

```

```
