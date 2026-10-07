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

## Decisions the design did not make

The approach and design will not settle everything. When they don't, decide like a senior engineer
the user trusts to finish the slice and report back. Stopping to ask is the exception.

**Decide it, record it and continue** when reverting this branch's commits would undo it and it
contradicts no property, done-when item or recorded decision on the ticket. Choose the option that
best delivers the ticket's properties. Record it as a departure: what the approach or design said,
what you did instead, the options you weighed, the property that decided it, and how to reverse it.

**Escalate** only when the decision:

- contradicts a property, a done-when item or a recorded decision on the ticket, or would drop a
  planned test, assertion or telemetry item;
- adds a new dependency or external service, a persistent data shape, a public interface (an API,
  a CLI contract, a file format), a new process or runtime, or a user-facing pattern people will
  learn;
- takes effect outside this branch: other repos, remote state, credentials;
- risks security or data loss.

Subagents follow the same rule. They decide what they may, report it under `DEPARTURES`, and return
`escalate` only for the cases above.

The steps of this skill are not decisions. Nobody is watching, so an unattended run verifies more
than an attended one, never less. A step that does not run in full, such as a review with fewer
reviewers than its skill names, a skipped mutant or a missing proof, is run again. If it still
cannot run in full, escalate. A small diff is never a reason to run less.

## Your role

You coordinate. Subagents do the heavy work, so that check output, diffs and review rounds stay
out of your context and you still have the plan in view at the last step. You keep the ticket's
approach and design comments, the step 4 table, a one-line outcome per step, and every escalation.

You are the only agent that posts to GitHub. A subagent that needs a decision returns it to you,
and you escalate it.

Run artifacts go in `unattended/<issue>/` under your session's scratchpad directory. Pass its
absolute path to every subagent. Subagents write logs there with shell redirection and return
reports as text, because the harness refuses report files written by subagents.

This session is isolated in its worktree. The isolation refuses compound shell commands that mention
`git` or values computed at runtime, and writes outside the worktree. Run plain, separate commands,
and tell every subagent to do the same.

### What every subagent returns

Tell each subagent to end its reply with exactly this block, and nothing after it:

```
STATUS: pass | fail | escalate
ARTIFACTS: <absolute paths of the logs and files it wrote>
SUMMARY: <150 words or fewer>
DEPARTURES: <each decision it made that the approach or design did not, recorded as above, or "none">
ESCALATION: <the decision needed and two or more numbered options, or "none">
```

Keep every departure the subagents report, and your own, in one list for step 9.

A subagent's report is evidence, not a finding. Before you act on a `pass`, confirm that its
artifacts exist and read the exit-code line of at least one log. A `pass` you cannot confirm counts
as a `fail`.

## Escalate

1. Comment on the ticket: what you found, the decision needed, and two or more numbered options,
   each with its consequence and your recommendation. List the departures made so far below it.
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

Spawn a **test-writer** subagent. Give it the repo path, the design comment, and the parts of the
approach comment that say what must be true and why: **What this must make true**, **What does not
bind here**, **Constraints** and **Done when**. Do not give it the **Approach** or **Alternatives
that lost**, so its tests describe behaviour rather than the planned mechanism.

It writes every test in the design comment's **Tests** section, runs them, and confirms that each
fails for the reason the design gives, not because of a compile error, missing import or typo.
Where the design says a test passes before the change, it confirms that instead. It saves that
output as an artifact and returns each planned test with the `file:line` where it lives.

It owns the quality of the suite, not just its transcription. Where a planned test would not catch
every way its property could break, including in code added later, it strengthens the test or adds
one, and reports each as a departure. It never weakens or drops a planned test. If a test cannot be
set up the way the design describes, it finds a setup that observes the same property and reports
that as a departure too.

Commit the tests once the status is `pass`, so step 3 can be checked against them. Keep the
test-writer's agent ID for step 4.

## 3. Green

Spawn an **implementer** subagent. Give it the approach and design comments, the test files from
step 2, and the list of check commands. It implements the approach in the smallest change that
makes those tests pass, following `uphold-standards`, adds each assertion from **Assertions** and
each signal from **Telemetry**, and runs the full checks until green. It does not edit the test
files from step 2. Choices the design did not make follow the rule under "Decisions the design did
not make".

When it returns, confirm with `git diff <tests commit> -- <test files>` that the test files are
unchanged. If they changed, the implementation is not trusted: escalate with the diff.

Keep this implementer's agent ID. Every later fix to the implementation goes back to it with
SendMessage, so it works from what it already learned about the code rather than a fresh agent
learning it again. Each time it returns, repeat the test-file check above.

## 4. Audit the plan against the work

Make a table of every test, assertion and telemetry item in the design comment, each with the file
and line that implements it and the artifacts showing it fail and then pass. Confirm each location
with `grep` or `git` yourself rather than taking it from a summary. A row you cannot fill is
unfinished work: a missing test goes back to step 2, and a missing assertion or signal goes to the
step 3 implementer. A planned item that was deliberately left out is an escalation.

Then send the test-writer back, with SendMessage, to prove each property's tests can fail. For each
property, it breaks the implementation in one place that property depends on, runs the suite,
confirms it goes red, restores the file with `git checkout -- <file>` and confirms `git status` is
clean. It reports each mutant and the test that caught it. A mutant the suite misses means a test
is too weak: the test-writer strengthens it, as a departure, and the mutant is run again. Commit any
strengthened tests, and confirm the implementation still passes them.

## 5. Review

Commit the work, then spawn a subagent to run `review-converge` on this branch. Tell it to run every
reviewer `review-code` names, whatever the size of the diff, and to return their names as a roster
in its summary. It applies the auto-fixes and returns its report, with every finding it could not
auto-fix under `ESCALATION`. A roster shorter than `review-code`'s set means the review did not run
in full: run it again. Escalate the findings it could not auto-fix on the ticket.

Then spawn a fresh checks subagent to run the same commands again, rather than taking the review's
word that the branch is still green. If any fail, send the failures to the step 3 implementer and
run the checks again once it returns.

## 6. Prove it

Spawn a subagent to run `prove-it-works` on the change. Its artifacts are the commands it ran,
their exit codes and the output it captured. "Tests pass" is not evidence for this step. Before
using its verdict, open one captured output yourself. If it shows the change does not work, send
its evidence to the step 3 implementer, run the checks again, then run this step again.

## 7. Open the PR

Commit with the `commit` skill and push. Open a draft PR using `write-pr-description`, omitting any
field that would need to ask the user. Keep the body short: the ticket comments hold the detail, and
the PR links to them. Add one line to each section:

- **What:** `Design: <link to the design comment>`
- **Why:** `Approach and the properties it had to deliver: <link to the approach comment>`
- **Related:** `Closes #<n>`

Step 9 adds the link to the run report under **Validation** once that comment exists.

## 8. Independent review of the PR

Spawn a fresh subagent and give it only the PR number and repo, not the ticket, the plan or anything
from this run, so its review is independent of them. It runs `review-code` on the PR with every
reviewer, posts nothing, and returns the verdict and every finding with its severity.

Send each "must" and "should" finding to the step 3 implementer, run the checks again, push, and
spawn another fresh reviewer. Repeat until a review returns no "must" or "should" findings, for up
to 5 rounds. If findings remain after the fifth, escalate them. "Consider" findings are listed, not
fixed.

## 9. Report the run

Post one run-report comment on the ticket, with these sections:

1. **Properties:** a table with one row per property from the approach comment: what observes it,
   its result before the change, its result after, and the mutant it caught.
2. **Evidence:** what `prove-it-works` ran and what it saw, before and after the change.
3. **Reviews:** one line per review round, from step 5 and step 8, with its number of "must",
   "should" and "consider" findings, how they were resolved, and the "consider" findings left open,
   so it is visible which round found what.
4. **Departures:** a numbered list of every departure from the approach and design, each with what
   was planned, what was done, the options weighed, the deciding property and how to reverse it.
   Write "No departures" when there were none.
5. **Not verified:** anything the run could not observe, and why.

Then edit the PR body with `gh pr edit` to add one line under **Validation**:
`Run evidence, mutants and review rounds: <link to the run-report comment>`. Print `PR: <url>` as
the final line.
