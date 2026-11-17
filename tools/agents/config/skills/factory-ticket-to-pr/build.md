# Build stage

## Rules of this stage

When the work has to change the approach or the design, post a comment on the ticket saying what
changes and which step of the chain it changes, as the global `CLAUDE.md` asks, before acting on it.
Subagents report such changes under `PLAN CHANGES`, and return `stop` only where "Stop only here" in
`SKILL.md` says to.

The steps of this skill are not decisions. Nobody is watching, so an unattended run verifies more
than an attended one, never less. A step that does not run in full, such as a review with fewer
reviewers than its skill names, a skipped mutant or a missing proof, is run again. If it still
cannot run in full, stop. A small diff is never a reason to run less.

A finding from any review is resolved only by a change that makes it no longer true: a fix to the
code or the tests, or a correction to a claim that says more than is true. Recording the gap as
known, in a doc or a comment, does not resolve it. Fix it, or show it is wrong as step 8 says. A
finding that the approach or the design should change is a change to the plan, as above.

## Your role

You keep the ticket's approach and design comments, the step 4 table and a one-line outcome per
step.

Run artifacts go in `unattended/<issue>/` under your session's scratchpad directory. Pass its
absolute path to every subagent. Subagents write logs there with shell redirection and return
reports as text, because the harness refuses report files written by subagents.

This session is isolated in its worktree. The isolation refuses compound shell commands that mention
`git` or values computed at runtime. Run plain, separate commands, and tell every subagent to do the
same.

### What every subagent returns

Tell each subagent to end its reply with exactly this block, and nothing after it:

```
STATUS: pass | fail | stop
ARTIFACTS: <absolute paths of the logs and files it wrote>
SUMMARY: <150 words or fewer>
PLAN CHANGES: <each change to the approach or design it made, or "none">
STOP: <what stopped it, as "Stop only here" in SKILL.md describes, or "none">
FRICTION: <its Friction list, as SKILL.md describes, or "None">
```

Before you act on a subagent's `pass`, confirm that its artifacts exist and read the exit-code
line of at least one log. A `pass` you cannot confirm counts as a `fail`.

## 1. Check the inputs

1. The ticket is the second argument and the run ID the third. Add a `build` section to `run.md` in
   the run folder. If the folder does not exist, because the build was started by hand, create it
   with `run.md`'s header.
2. Read the ticket with all its comments (`gh issue view <n> -R <repo> --json title,body,comments`).
3. Find the approach comment (it starts with `# Approach`) and the design comment (it starts with
   `# Design`). The approach's property table (`P1`, `P2`, …) is the done-when: the work is done
   when every property in it holds. If either comment is missing, stop: this skill does not plan.
4. Confirm the worktree is clean and on its own branch, not the default branch.
5. Spawn a **checks** subagent. It finds the repo's check and test commands (CLAUDE.md, AGENTS.md,
   CONTRIBUTING.md, justfile, package.json, CI config), runs every one, and writes each command's
   full output to the artifacts directory. Its summary lists each command with its exit code and the
   first failing lines. Keep the list of commands it found, since every later checks subagent runs
   the same list. If any fail before you change anything, the base branch is already broken. Where
   the fix is mechanical and needs no decision, such as a formatting or line-length problem, send it
   to a subagent to fix in its own commit on this branch, and run the checks again. A fix that needs
   a decision is decided under "Decisions nobody made", made in its own commit, and named in the
   PR's **What**.

## 2. Red

Spawn a **builder** subagent. Give it the repo path, the approach and design comments, and the
list of check commands. It works in the red-green steps the global `CLAUDE.md` describes, and
returns once its tests fail, before it writes any implementation, so you can check the tests on
their own.

It writes a test for every row of the design comment's **Tests** table, using the technique the row
names. The design leaves setup to it, so it works out how to set each test up and what each should
do before the change: fail, for a behaviour the change adds, or pass, for one the change must
preserve. It runs them and confirms each result is the one it predicted, and that a failure comes
from the missing behaviour, not a compile error, missing import, typo or broken setup. It saves
that output as an artifact and returns each test with the `file:line` where it lives and the
property it observes.

It owns the quality of the suite, not just its transcription. Where a planned test would not catch
every way its property could break, including in code added later, it strengthens the test or adds
one, and reports each in its summary. It never weakens or drops a planned test. If a test cannot be
set up the way the design describes, it finds a setup that observes the same property and reports
that under `PLAN CHANGES`.

When the builder returns at red, open its saved output yourself. Confirm that each test of a
behaviour the change adds fails with a message about that behaviour, and that each test of a
behaviour the change must keep passes. A failure from an import error, a typo or a broken setup goes
back to the builder before anything goes on to green.

Don't commit the tests yet: every commit holds passing work, and some repos refuse any other. Copy
the test files into `red/` in the artifacts directory, so step 3 can be checked against them. Keep
the builder's agent ID: every later step that changes the tests or the implementation goes back to
it with SendMessage, so it works from what it already learned about the code rather than a fresh
agent learning it again.

## 3. Green

Send the builder on to green with SendMessage. It implements the approach in the smallest change
that makes its tests pass, following `uphold-standards`, adds each assertion from **Assertions** and
each signal from **Telemetry**, and runs the full checks until green. It does not edit its tests
from step 2. Choices the design did not make follow "Decisions nobody made" in `SKILL.md`.

When it returns, confirm with `diff` against the copies in `red/` that the test files are unchanged.
If they changed, send the builder back to restore them and make the code pass them as written. Then
commit the tests and the implementation together. Each time the builder returns from a later fix,
repeat this check.

## 4. Audit the plan against the work

Make a table with one row per item of the design comment's correctness plan: each step of the type
progression, each assertion, each telemetry entry and each test. Each row gives the file and line
that implements it and shows it does what the design says: for a type step, the code that makes
impossible what the design says that step rules out; for an assertion, its condition and site; for a
telemetry entry, what it records and where; for a test, the artifacts showing it fail and then pass.
Confirm each row yourself with `grep`, `git` or by reading the code, rather than taking it from a
summary. A row you cannot fill is unfinished work and goes back to the builder. A planned item
deliberately left out is a change to the plan, recorded on the ticket as the rules above say.

Then prove each property's protection can fail, with mutants chosen by someone other than the person
who wrote the tests. Spawn a **mutant** subagent. Give it the repo path, the check commands and the
approach comment's **What a good fix must achieve**, **Assumptions** and **Constraints**. Tell it
not to open the test files, so its mutants aim at where the property could break rather than at what
the tests already cover.

For each property, it breaks the implementation in every kind of place that property depends on:
each instance of a cross-cutting property (every command, every branch, every machine), not one
representative. After each break it runs the tests that load the changed file, found with
`grep -rl <file name>` over the test files without opening them, and records whether they went red.
A mutant counts as caught when the testing standard counts the break as confirmed, so it also runs
the type checker on each. A mutant those tests miss is run once more against the full suite before
it counts as a survivor, because a test elsewhere may catch it. Then it restores the file with
`git checkout -- <file>` and confirms `git status` is clean. It reports each mutant and whether it
was caught.

A mutant nothing catches means the protection is too weak. Send the survivors to the builder with
SendMessage. It strengthens the protection: a test, a type or an assertion, whichever the design
would have chosen, and the survivors are run again until all are caught. Commit any strengthened
tests, refresh their copies in `red/`, and confirm the implementation still passes them.

## 5. Commit and check again

For each `Decided without you` entry in the approach or design comment, and each decision this
stage took that a triage test held for, commit a decision record, in the folder where the repo keeps
its decision records and in that folder's format, built from the decision, its options, its reason
and what would reopen it. In a repo with no such folder, copy the entries into the PR body's
**What** section in step 7 instead. Then run `wrap-up-codebase` on the branch, as the global
`CLAUDE.md` does before a draft PR. Send its fixes to the builder, and settle each of its
asks under "Decisions nobody made".

Spawn a fresh checks subagent to run the same commands again on the committed work. If any fail,
send the failures to the builder and run the checks again once it returns.

## 6. Prove it

Spawn a subagent to run `prove-it-works`, giving it the approach comment's property table as the
claim to prove. Its report points each quote at the raw output it saved in the evidence folder
it names, and shows the attempts that failed. "Tests pass" is not evidence for this step. Before
using its verdicts, open one cited observation file in that folder yourself. If a finding is
disproven, send its evidence to the builder, run the checks again, then run this step
again.

## 7. Open the PR

Open the draft PR with the `create-pr` skill, giving it step 6's evidence folder so the description
can show what the proof saw. Its checks already passed in step 5, and its description omits any
field that would need to ask the user. Add the `Decided without you` entries under **What** when
step 5 found no record folder. Record the PR's URL in `run.md`.

## 8. Review the PR

Spawn a fresh subagent and give it only the PR number and repo, not the ticket, the plan or anything
from this run, so its review is independent of them. It runs `review-code` on the PR, posts nothing,
and returns `review-code`'s report word for word.

Send every finding to the builder in the reviewer's words. Settle each `?` question
under "Decisions nobody made" first. A finding that the approach or design should change is a
change to the plan: before sending it, post the ticket comment the global `CLAUDE.md` asks for,
saying what changes and which step of the chain it changes. A finding the builder shows to be
wrong, with a command it ran, is left unchanged, with that evidence beside it. Run the checks and
step 6's proof again, and push. The review gets one round, as the global `CLAUDE.md` says, so no
review follows the fixes.

Then post one comment on the PR headed `Automated review`, holding the report inside a collapsed
`<details>` block, with the commit that fixed each finding below it.

## 9. Finish

Copy step 6's evidence folder into the run folder as `evidence/`. Finish the run record, then print
`PR: <url>` as the final line.
