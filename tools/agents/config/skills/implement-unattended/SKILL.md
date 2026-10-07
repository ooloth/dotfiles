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
4. Find the repo's check and test commands (CLAUDE.md, AGENTS.md, justfile, package.json, CI
   config) and run them. If they fail before you change anything, escalate.

## 2. Red

Write every test in the design comment's **Tests** section. Run them and confirm that each one fails
for the reason the design gives, not because of a compile error, missing import or typo. Keep the
failing output, since the PR body shows it.

## 3. Green

Implement the approach in the smallest change that makes those tests pass, following
`uphold-standards`. Add each assertion from **Assertions** and each signal from **Telemetry**. Run
the full checks and tests until green. If making them pass needs a choice the design did not make,
escalate.

Count each run of the full checks in this step. If the tenth run still fails, escalate, with the
failures from the last run in the comment.

## 4. Audit the plan against the work

Make a table of every test, assertion and telemetry item in the design comment, each with the file
and line that implements it and the run where it was seen to fail and then pass. A row you cannot
fill is unfinished work, so go back to step 2 or 3. A planned item you deliberately left out is an
escalation.

## 5. Review

Commit the work, then run `review-converge` on this branch. Apply its auto-fixes. Any finding it
escalates is escalated on the ticket as above. Re-run the full checks after its last round.

## 6. Prove it

Run `prove-it-works` on the change and keep what it ran and what it observed. "Tests pass" is not
evidence for this step.

## 7. Open the PR

Commit with the `commit` skill and push. Open a draft PR using `write-pr-description`, omitting any
field that would need to ask the user. The body includes `Closes #<n>`, the step 4 table, the red
output from step 2, the `prove-it-works` evidence, and the `review-converge` report. Comment on the
ticket with the PR link. Print `PR: <url>` as the final line.
