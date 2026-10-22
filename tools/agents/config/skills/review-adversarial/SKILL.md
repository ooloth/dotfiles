---
name: review-adversarial
description: Try to break a change with independent fresh-context reviewers who see only primary sources, attack the properties the work promised, prove findings with failing tests in isolated worktrees, and report unfiltered. Use before merging a change you or this agent wrote, or whenever a review must not inherit the author's framing.
argument-hint: '[pr number or branch]'
effort: high
model: opus
---

# Adversarial review

The author of a change can't review it neutrally: whoever writes the reviewers' brief decides what
they look for. This skill keeps the author out of every step where their framing would steer the
result, and makes the evidence executable so that judging a finding needs as little judgement as
possible.

## 1. Pin the scope

Record the head SHA and the base SHA. Review everything not yet independently reviewed, or the
whole PR: the base is the last commit before that work. When the PR's own commits are interleaved
with merges of other PRs, use the default branch as the base, and give reviewers the other PRs'
diffs to set aside. The diff command is `git diff <base> <head>`.

## 2. Collect the primary sources, verbatim

Make a review root with `mktemp -d` inside the scratchpad. Save into `<root>/sources/` the ticket
body and every comment (through `use-jira` or `use-gh`), the decision records the ticket names, and
the invariants docs for the paths the diff touches. Use each record as it stands at the head
commit. Copy them as they are, with no summary. The PR description is the author's framing, not a
source. Never write an intent block: reviewers given the author's summary judge the code against the
summary.

## 3. Derive the attack questions from the promises, not from the code

Take each numbered property and invariant the ticket and records set, and turn each related group
into one question of the form "find an input, sequence of requests or stored state in which P*n*
fails". For each property, also ask its opposite error: where does the code do what the property
requires when it shouldn't? Write them from the sources, not from your memory of the
implementation. Your blind spots about the code would otherwise become the reviewers' blind spots.
List any property no question covers, and why. Always add three more reviewers:

- **Failure paths:** "for every failure after the irreversible step, what does the process actually
  do?"
- **Open-ended:** "what is most wrong with this change?", with no hints
- **Mutation:** break the code on purpose and record which breakages the tests miss

## 4. Give each reviewer its own worktree

`git worktree add --detach <root>/<id> <head>`, one per reviewer. Prepare the environment once, for
example `uv sync --frozen` and a symlinked `node_modules`.

## 5. Launch every reviewer in one message

Run each attack question twice, once on Sonnet and once on Opus. The failure-paths reviewer also
runs on both models. Run the open-ended reviewer on Opus and the mutation reviewer on Sonnet. Every
prompt contains:

- **Rules:** edit only inside its worktree; no commits, pushes or posts; no real external
  endpoints; no subagents. Prefix every command with `timeout`, run test runners in single-run mode
  (`vitest run`, never watch), never run the whole suite, and never start a server.
- **Where to read:** the paths under `<root>/sources/` and the diff command.
- **About the tests:** "The tests in the diff were written by the author. Treat them as the
  author's claims, not as evidence."
- **The question.**
- **The deliverable**, under 400 words: severity, file and symbol, a concrete scenario, and
  evidence. A failing test in the worktree (path, command, output) is preferred over quoted code or
  docs. It says plainly what couldn't be confirmed, and lists what was tried if nothing was found.

No prompt contains the author's rationale, test results, or any claim that the change works.

## 6. Verify before relaying anything

Re-run every failing test yourself, and check that each fails on the assertion its reviewer
described, not on setup. Check any claim about the world outside the repo against its source
yourself. Mark each finding as reproduced, confirmed by reading, unconfirmed or disputed. Where you
think a finding is wrong, a fresh verifier agent decides, not you.

## 7. Report unfiltered

Group findings by defect. Give the number of reviewers who reached each one independently, and
keep reproduced findings separate from claimed ones. List every finding, low severity and
pre-existing included, and drop nothing. Name the limits: sources a reviewer couldn't read,
failures that were simulated, and any reviewer that didn't finish.

## 8. Clean up when the user is done

Keep the worktrees until the user no longer needs the probe tests, then remove them. Remove
anything tools wrote outside the review root.
