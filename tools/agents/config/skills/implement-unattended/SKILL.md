---
name: implement-unattended
description: Take a ticket whose approach and design are already approved through implementation, review and evidence to a draft PR, with nobody watching. Escalates decisions on the ticket and stops rather than choosing.
argument-hint: '<owner/repo#issue>'
disable-model-invocation: true
---

Ticket: $ARGUMENTS

## Authority

The user launched this skill on purpose, and that launch is the approval for everything below. It
overrides any loaded CLAUDE.md that says otherwise:

- No pauses for approval, and no questions to the user. Nobody is watching this session.
- Committing, pushing, opening a draft PR and commenting on the ticket are approved. Nothing else
  that is visible outside this repo is.
- Skills invoked below that end by asking the user something are run to their report, and the
  question is skipped.

What the launch does not approve is a decision. Anything the approved approach and design do not
settle is escalated, never defaulted. Escalating is a success for this skill. A PR built on a guess
is a failure, even if every check is green.

## Your role

You coordinate. Subagents do the heavy work, so that check output, diffs and review rounds stay
out of your context and you still have the plan in view at the last step. You keep the ticket's
approach and design comments, the step 4 table, a one-line outcome per step, and every escalation.

You are the only agent that posts to GitHub. A subagent that needs a decision returns it to you,
and you escalate it.

Run artifacts go in `$(git rev-parse --git-common-dir)/unattended/<issue>/`. That directory is
outside the worktree, so git never tracks it and removing the worktree does not delete it.

### What every subagent returns

Tell each subagent to end its reply with exactly this block, and nothing after it:

```
STATUS: pass | fail | escalate
ARTIFACTS: <absolute paths of the logs and files it wrote>
SUMMARY: <150 words or fewer>
ESCALATION: <the decision needed and two or more numbered options, or "none">
```

A subagent's report is evidence, not a finding. Before you act on a `pass`, confirm that its
artifacts exist and read the exit-code line of at least one log. A `pass` you cannot confirm counts
as a `fail`.

## Escalate

1. Comment on the ticket: what you found, the decision needed, and two or more numbered options,
   each with its consequence and your recommendation.
2. Commit any work in progress and push the branch, so nothing is lost when the worktree goes.
3. Stop. Print `ESCALATED: <one sentence>` as the final line.

## 1. Check the inputs

1. Read the ticket with all its comments (`gh issue view <n> -R <repo> --json title,body,comments`).
2. Find the approved approach comment (**What this must make true**, **Approach**, **Done when**)
   and the design comment (**Types**, **Assertions**, **Telemetry**, **Tests**). If either is
   missing, escalate: this skill does not plan.
3. Confirm the worktree is clean and on its own branch, not the default branch.
4. Spawn a **checks** subagent. It finds the repo's check and test commands (CLAUDE.md, AGENTS.md,
   CONTRIBUTING.md, justfile, package.json, CI config), runs every one, and writes each command's
   full output to the artifacts directory. Its summary lists each command with its exit code and
   the first failing lines. Keep the list of commands it found, since every later checks subagent
   runs the same list. If any fail before you change anything, escalate.

## 2. Red

Spawn a **test-writer** subagent. Give it the design comment and the repo path, and nothing about
how the change will be implemented. It writes every test in the design comment's **Tests** section,
runs them, and confirms that each fails for the reason the design gives, not because of a compile
error, missing import or typo. It saves that failing output as an artifact and returns each planned
test with the `file:line` where it lives.

Commit the tests once the status is `pass`, so step 3 can be checked against them.

## 3. Green

Spawn an **implementer** subagent. Give it the approach and design comments, the test files from
step 2, and the list of check commands. It implements the approach in the smallest change that
makes those tests pass, following `uphold-standards`, adds each assertion from **Assertions** and
each signal from **Telemetry**, and runs the full checks until green. It does not edit the test
files from step 2. If making the tests pass needs a choice the design did not make, it escalates.

When it returns, confirm with `git diff <tests commit> -- <test files>` that the test files are
unchanged. If they changed, the implementation is not trusted: escalate with the diff.

## 4. Audit the plan against the work

Make a table of every test, assertion and telemetry item in the design comment, each with the file
and line that implements it and the artifacts showing it fail and then pass. Confirm each location
with `grep` or `git` yourself rather than taking it from a summary. A row you cannot fill is
unfinished work, so return to step 2 or 3. A planned item that was deliberately left out is an
escalation.

## 5. Review

Commit the work, then spawn a subagent to run `review-converge` on this branch. It applies the
auto-fixes and returns its report, with every finding it could not auto-fix under `ESCALATION`.
Escalate those findings on the ticket. Then spawn a fresh checks subagent to run the same commands
again, rather than taking the review's word that the branch is still green.

## 6. Prove it

Spawn a subagent to run `prove-it-works` on the change. Its artifacts are the commands it ran,
their exit codes and the output it captured. "Tests pass" is not evidence for this step. Before
using its verdict, open one captured output yourself.

## 7. Open the PR

Commit with the `commit` skill and push. Open a draft PR using `write-pr-description`, omitting any
field that would need to ask the user. The body includes `Closes #<n>`, the step 4 table, the red
output from step 2, the `prove-it-works` evidence, and the `review-converge` report. Comment on the
ticket with the PR link. Print `PR: <url>` as the final line.
