---
name: merge-and-verify
description: Merge an approved pull request through a gate that checks it, watch the rollout until it is serving, prove its effect with prove-it-works, and offer to clean up its branches. Given one sentence naming the PR. TRIGGER when an approved PR is ready to merge, when a merged PR's deploy needs watching, or when asked to verify a PR in its environment.
argument-hint: 'An approved or merged PR, such as "react-clinops-siteoutreach#305"'
---

Input: $ARGUMENTS

If the PR has already merged, skip to "Watching the rollout" once you have worked out what is below.

## What to work out first

One sentence naming the PR is enough. Get the rest from the environment, and ask the user only for
what none of it holds, such as a credential only they can refresh.

- **The merge commit,** from the PR.
- **The ticket,** from a Jira key in the PR's branch, title or body, or an issue it closes. A PR
  with neither has no ticket; say so.
- **The claim to prove:** the ticket's properties, plus each side effect the PR's review named.
  Trace each part to the property or comment it came from.
- **The deploy chain,** from the docs of the repo and of every repo the deploy passes through, such
  as a GitOps repo: each stage between the merge and the running service, and how to read what is
  serving at the end. If the docs don't say how to read what is serving, stop and say what is
  missing. If the merge changed nothing that deploys, say so and why, skip the watch, and go
  straight to the proof.

## Merging

Before merging, report each check that takes judgement, with its result:

- **Trunk since the review:** the commits trunk gained since the PR's head was reviewed, the files
  both sides changed, and whether any of them, or a migration or dependency change on either side,
  could break what the PR relies on. If so, the branch needs trunk merged into it (merge, never
  rebase) and its checks run again before merging.
- **Review findings and unresolved threads:** each one, with the commit or reply that addressed it,
  or "not addressed". Unresolved threads are normal here. A finding blocks only when nothing
  addressed it and the reviewer didn't mark it optional, a nit or non-blocking; list the rest
  without blocking on them.
- **The repo's merge-time steps:** anything its docs say must happen before or after a merge, such
  as running a migration before the deploy reaches it.
- **Timing:** whether another PR has to land first, or anything else makes now the wrong moment.

If one fails, stop and say what would fix it. Where the claim's before state will be gone once the
deploy lands, observe it now with `prove-it-works`, in the merge's evidence folder once you know the
merge commit, or under the PR's head commit until then.

Then merge through the gate, passing the full head commit you checked:

```sh
uv run <skill-base-dir>/scripts/merge.py <pr> --repo <owner>/<repo> --head <sha> [--check-only]
```

It refuses unless the head is unchanged, the PR is open and not a draft, someone approved that exact
head with no outstanding change request, every check on it passed and GitHub says it can merge. It
prints every failed condition at once. Never merge any other way: not `gh pr merge`, not the button
in a browser. `--check-only` reports readiness without merging, for showing the user before you ask.

## Watching the rollout

**Serving** means the live artifact (a revision, an image digest, the tag that digest carries) was
built from the merge commit or from a later trunk commit that contains it, as GitHub's compare of
the two says. A run's status, a pipeline's "success" or a health badge never counts. Name the
artifact you read.

Each check reads the whole chain from scratch, so a check after a restart, a closed session or a
missed check needs nothing remembered. Save each command's raw output in the evidence folder
`prove-it-works` uses for the merge commit, `~/Repos/agents/prove-it-works/<owner>-<repo>/<merge
commit>/`, in a new subfolder for this watch. Then report what changed since the last check, as a
finished message.

Between checks, schedule the next one about 5 minutes out with a one-shot `CronCreate` whose prompt
says to continue this watch, and end the turn, so each report reaches the user and the session is
free in between. Where `CronCreate` doesn't exist, sleep between checks instead and say that
reports will arrive together.

The watch ends in exactly one of these, and the report names which:

- **Serving,** with the artifact and the compare that shows it contains the merge.
- **A stage failed,** naming the stage and quoting its output.
- **A new revision failed to start while an older one still serves,** quoting its condition.
- **Waiting on a person,** saying who and for what, such as an approval step or a manual migration.
- **Credentials expired,** with the command the user runs to refresh them.
- **Nothing deploys.**
- **Pinned or rolled back:** what is serving does not contain the merge and is not an older commit
  still waiting to be replaced.
- **The deadline passed:** 60 minutes after the PR's `mergedAt` with no other ending.
- **Repeated errors** reading a stage, after a retry and the obvious alternatives.

A check that can't read a stage never reports "still rolling out". The deadline ends only a watch
that is still waiting: a watch started after it still checks once, and reports whatever that check
finds.

Read remote state through `gh` and each provider's own CLI or API. Don't `git fetch` or otherwise
change a local clone to read it.

## The proof

Once the change is serving, or nothing deploys, run `prove-it-works` with the claim, using the same
evidence folder. Show the user a draft report: the PR, merge commit and ticket, the claim and where
each part came from, the rollout from merge to its ending, and the `prove-it-works` report
unchanged. Post nothing, and change nothing in any deployed environment.

## Cleaning up

Only after a "serving" ending with a proof, offer to remove the PR's leftover local branches and
worktrees, in every clone and worktree of the repo on this machine. A branch qualifies only when its
tip is one of the PR's own commits, as GitHub lists them for the PR, so trunk and branches resting
on older trunk commits never match. A worktree qualifies when its checked-out branch does. Never
offer:

- a worktree with uncommitted or untracked files
- a worktree a running session, terminal tab or process has open
- the main checkout of a repo, even on the PR's branch: say it would need to switch to the default
  branch first
- a branch another open PR is based on

List each candidate with why it qualifies, and each one you left out with why. Remove only what the
user confirms, with `git worktree remove` and then `git branch -D`, never by deleting folders.
`-D` is needed because a squash merge leaves the branch's commits out of trunk, so `-d` always
refuses; the check above, that the tip is one of the PR's own commits, is what makes it safe.
