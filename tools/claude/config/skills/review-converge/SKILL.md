---
name: review-converge
description: Autonomously review and fix the current branch or specified scope in iterative rounds until clean, leaving all changes in the working tree. Escalates only design decisions and non-obvious judgment calls. Ends with a transparent report of every round, every fix, and anything it couldn't resolve.
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

**Auto-fix** — all of the following must be true:
- There is one clearly correct fix
- Implementing it requires no design choice or trade-off judgment
- It does not change a public API, data model, or contract in a way that needs deliberate owner
  sign-off

**Escalate** — any of the following applies:
- Multiple valid approaches exist and the right one depends on requirements or preferences
- The fix would change a public API, data model, or contract
- Correctly fixing it requires context only the author or team has
- It is a non-obvious judgment call about trade-offs

Note: a Critical severity finding with an obvious correct fix is **auto-fix**, not escalate.
Severity and escalation status are independent.

### Step C — Check for Repetition

Compare this round's findings against all previous rounds. A finding is **repeated** if the same
issue at the same location appeared in a prior round after a fix was attempted. Record it as a
repetition with a note on what was tried.

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

Record what was changed (file, issue, fix applied) for the report.

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

#### Round 1
- `file:line` — [issue description] — [fix applied]
- `file:line` — [issue description] — [fix applied]
...

#### Round 2
- `file:line` — [issue description] — [fix applied]
...

#### Round N
[Clean — no auto-fixable findings.]  ← if loop exited cleanly

---

### Repeated findings (could not resolve)

These issues reappeared in a later round after a fix was attempted. The coordinator was unable to
converge on a solution — these need your attention.

- `file:line` — [issue] — Attempted: [what was tried in round N] — Still present in round N+1
  because: [coordinator's best guess at why]

(None)  ← if no repetitions

---

### Escalated items (need your input)

These findings were not auto-fixed because they require a design decision or non-obvious judgment.

- `file:line` — [issue] — Why escalated: [reason — e.g. "two valid approaches, depends on whether
  X or Y is preferred", "changes public API contract"]

(None)  ← if nothing escalated

---

### Working tree
All changes are uncommitted. Run `git diff` to review before committing.
[N total files modified]
```

---

## Guardrails

- **Max 5 rounds** — always. Never loop indefinitely.
- **No commits** — ever. Working tree only.
- **No scope creep** — only fix findings from the review. Do not refactor, clean up, or improve
  things outside the reported findings.
- **No silent changes** — every change made must appear in the report.
- **Repetition is data** — if a fix doesn't hold across a round boundary, record it honestly
  rather than trying increasingly speculative fixes. Two failed attempts = escalate it.
