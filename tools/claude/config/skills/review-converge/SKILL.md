---
name: review-converge
description: Autonomously review and fix the current branch or specified scope in iterative rounds until clean, leaving all changes in the working tree. Escalates only genuine design decisions. Ends with a transparent report of every round, every fix, and anything it couldn't resolve.
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

This intent context is passed to every review subagent so it understands what the changes are
trying to accomplish — not just what changed.

---

## Phase 2: Converge Loop

Run up to **5 rounds**. Before each round, emit:

```
Round N/5: reviewing...
```

### Step A — Review (subagent)

Use the Agent tool (general-purpose) to run the `review-code` analysis. Pass it:

- The scope (files or diff range)
- The intent context from Phase 1
- Instruction to read full file context (not just diffs) wherever needed to evaluate a change in
  its proper context — e.g. when a change's correctness depends on how callers use it, or when
  the surrounding code is needed to judge whether a pattern is consistent
- Instruction to follow the `review-code` skill's analysis process and return findings in the
  standard format: Praise / Issues (Critical, Important, Minor) / Questions / Patterns Observed

Wait for the subagent to return findings.

### Step B — Classify Findings

Partition every Issue finding into one of two buckets:

**Auto-fix** — there is one clearly correct answer. This includes:

- Obvious correctness fixes (bugs, missing error handling, unquoted variables, etc.)
- Consistency fixes with no ambiguity (matching the pattern used everywhere else)
- Conservative improvements on working code (defensive quoting, minor style alignment)
- The mechanical part of a mixed finding — see splitting rule below

The test is: *does applying this require the author to make a choice?* If no, auto-fix it.

**Escalate** — the right answer genuinely depends on a decision only the author can make:

- Multiple valid approaches exist and the choice depends on requirements or preferences
- The fix would change a public API, data model, or contract
- Correctly fixing it requires intent or context only the author has

Note: severity and escalation status are independent. A Critical finding with an obvious correct
fix is **auto-fix**. A Minor finding with two reasonable approaches is **escalate**.

**Splitting rule:** If a finding contains both a mechanical sub-fix and a design sub-question,
apply the mechanical sub-fix and escalate only the design question. Never hold a mechanical fix
hostage to an unresolved design question.

### Step C — Check for Repetition

Compare this round's findings against all previous rounds. A finding is **repeated** if the same
issue at the same location appeared in a prior round after a fix was attempted. Record it as a
repetition with a note on what was tried.

**One failed attempt = escalate.** Do not attempt a second fix for the same issue — record it
as a repetition and move on.

### Step D — Decide Whether to Continue

Emit one of:

```
Round N/5: [X] auto-fix, [Y] escalate, [Z] repeated
```

Then:

- If there are **no auto-fix findings**: exit the loop (clean or only escalations/repetitions remain)
- If the **round limit is reached**: exit the loop
- Otherwise: continue to Step E

### Step E — Fix (subagent)

Before spawning the fix subagent, verify any file paths referenced in the findings actually exist
(`ls` or `fd`). Correct a wrong path before passing it to the subagent; if the right path is
ambiguous, escalate the finding instead.

Use the Agent tool (general-purpose) to implement all auto-fix findings from this round. Pass it:

- The complete list of auto-fix findings with their suggested fixes from the review output
- The file paths and relevant context
- Instruction: implement every finding exactly as described; do not make additional changes; do
  not commit anything

Wait for the subagent to complete.

Emit:

```
Round N/5: applied [X] fixes
```

Record what was changed (file, issue, fix applied, before/after snippet) for the report.

Then return to the top of the loop for the next round.

---

## Phase 3: Report

Once the loop exits, generate a plain-text report. Emit it directly in the conversation (no HTML
deck — this is a workflow summary, not a discovery report).

```
## review-converge report

**Scope:** [resolved scope]
**Rounds completed:** N of 5
**Outcome:** [Clean | Escalations remaining | Repetitions unresolved | Round limit reached]

---

### Changes made

Leave a blank line before and after every diff block so items don't run together.

#### Round 1

- `file:line` — [issue] — [fix applied]

  ```diff
  - [before, max 3 lines]
  + [after, max 3 lines]
  ```

- `file:line` — [issue] — [fix applied]

  ```diff
  - [before]
  + [after]
  ```

#### Round 2
...

#### Round N
[Clean — no auto-fixable findings.]  ← if loop exited cleanly

---

### Repeated findings (could not resolve)

These issues reappeared after a fix attempt. One attempt was made; escalating rather than
speculating further.

- `file:line` — [issue] — Attempted: [what was tried] — Why it didn't hold: [best guess]

(None)  ← if no repetitions

---

### Escalated items

These require a decision from you. Each lists the options so you can reply with a number or letter.

1. `file:line` — [issue] — Why escalated: [reason]
   - (a) [option]
   - (b) [option]
   - (c) [option if applicable]

2. `file:line` — [issue] — Why escalated: [reason]
   - (a) [option]
   - (b) [option]

(None)  ← if nothing escalated

---

### Working tree
All changes are uncommitted. Run `git diff` to review before committing.
[N total files modified]

---

**To resolve escalations:** reply with your decisions (e.g. "1b, 2a") and I'll apply them and
do one final pass.
```

---

## Guardrails

- **Max 5 rounds** — always. Never loop indefinitely.
- **No commits** — ever. Working tree only.
- **No scope creep** — only fix findings from the review. Do not refactor, clean up, or improve
  things outside the reported findings.
- **No silent changes** — every change made must appear in the report with a diff snippet.
- **One attempt per issue** — if a fix doesn't hold, escalate immediately rather than speculating.
- **Split, don't bundle** — never hold a mechanical fix hostage to an unresolved design question.
