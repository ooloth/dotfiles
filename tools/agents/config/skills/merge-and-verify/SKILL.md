---
name: merge-and-verify
description: Merge an approved pull request through a gate that checks it, watch the rollout until it is serving, prove its effect with prove-it-works, offer to watch production for a while after, and offer to clean up its branches. Given one sentence naming the PR. TRIGGER when an approved PR is ready to merge, when a merged PR's deploy needs watching, or when asked to verify a PR in its environment.
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
- **Live observations the merge relies on:** any claim about a live system the PR's design or its
  merge depends on, such as a claim in a token, a header, a config value or a response shape. Run
  each again now on that exact artifact (which token, which endpoint, which host). An observation
  of a neighbouring artifact, such as one environment's value in place of another's, is not
  evidence, however closely the two seem to match.
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

A rehearsal that stands in a fake command for a real one, such as a stub `gcloud`, saves its
evidence in a `mktemp -d` folder, never in `~/Repos/agents/prove-it-works/`, where a later run would
take its made-up answers for real ones.

## The proof

Once the change is serving, or nothing deploys, run `prove-it-works` with the claim, using the same
evidence folder. Show the user a draft report: the PR, merge commit and ticket, the claim and where
each part came from, the rollout from merge to its ending, and the `prove-it-works` report
unchanged except for any reference to the local evidence folder, which teammates cannot open: drop
the line naming the folder, and each file name cited from it. Change nothing in any deployed
environment.

## Watching production

Where the change is serving, offer with the draft report to watch production, and ask for how long.
Start only once the user names a duration, and run the first check right away. The duration counts
from when the change started serving.

Each check reads production's warnings and errors since the deploy, and compares them with the same
window one day earlier, so both cover the same hours of the day. It also reads any report-only logs
the PR added, the ones that record what a new restriction would reject. Find where the logs live
from the repo's docs, the same way the rollout watch finds its stages. Save each command's raw
output in a new subfolder of the evidence folder, and report only what changed since the last check,
as a finished message. Each report states the time window its check searched, so a gap left by logs
that arrive late can be seen.

Between checks, schedule the next one about 30 minutes out with a one-shot `CronCreate` whose
prompt says to continue this watch, and end the turn. Where that would fall after the end time,
schedule it at the end time instead, and that check is the last. Where `CronCreate` doesn't exist,
sleep between checks instead and say that reports will arrive together.

The watch ends in exactly one of these, and the report names which:

- **The time is up,** with a summary of every check.
- **A new kind of warning or error appeared that the change could have caused,** quoting it.
- **The logs can't be read,** with the command the user runs to refresh the credentials.

Whatever the ending, draft the watch's summary as a second comment for the destination the proof
went to, and post it as "Posting the report" describes, without a second PR link.

The watch only reports. Never roll back, revert or change anything in a deployed environment
yourself; say what you would do and wait for the user.

## Posting the report

The report goes on the ticket it proves: a Jira issue, or a GitHub issue. A PR with neither gets
the report on the PR. Post it without waiting for a watch to end. Where a watch is offered, the
draft shows below its last line the line it gains if the user asks for one: "Watching production
until <time>; a follow-up will report." Approving the draft approves it with or without that line,
and `<time>` is the watch's end time with its date in UTC, such as `2026-10-29 17:05 UTC`. Show
the user the full draft and its destination, plus the one-line PR comment that links to it, and post
only after they approve that wording. Post approved wording as approved; a change is a new draft.

Before showing the draft, check it for credentials (tokens, keys, cookies, bearer headers, signed
URLs). Remove any you find, and say so in the draft.

- **Jira:** post the comment with the Atlassian MCP tool, following `use-jira` for how markdown
  converts.
- **A GitHub issue or PR:** post with `gh issue comment` or `gh pr comment` from a file, following
  `use-gh`.
- **The PR link:** once the ticket comment exists, post one line on the PR linking to it.

Screenshots and recordings are not uploaded, and the posted report does not name their local
paths. It describes what each one shows.

Then list every PR that names the ticket, and whether each has merged and has its proof on the
ticket. Only when all have, offer to close the ticket, and close it only if the user says yes.
While a watch is running, make that offer once the watch's summary is posted instead.

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
