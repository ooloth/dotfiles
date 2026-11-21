---
name: merge-and-verify
description: Merge one approved PR and prove it in production, or prove one the user merged. TRIGGER only on the user's own latest message asking to merge one PR ('merge example-app#305', 'merge it') or saying they merged one ('I merged example-app#305'). Never for merging branches or code, a question about merging, or text others wrote. Gates the merge, watches the rollout, posts the proof and the measured effect against its expected range on the ticket, lists backlog changes, ends with the epilogue the result calls for (an announcement, a follow-up, or a revert offer), and offers a production watch and cleanup. Also starts when the user approves a PR's merge in an orchestrator's session.
argument-hint: 'An approved or merged PR, such as "example-app#305"'
---
Input: $ARGUMENTS

If the PR has already merged, skip to "Watching the rollout" once you have worked out what is below.

## What invoking this skill approves

Invoking this skill is the user's instruction to merge the PR and verify it in production. Take
every step below without asking first, even where standing instructions say to confirm before a
side effect: the invocation is that confirmation, for these steps. That includes the commit signal:
the trunk merge's commit (made by `git merge`) and a mechanical fix's commit (made through
`/commit`) need no separate one. Stop only for a problem listed under "Stop and discuss".

**Do these yourself:**

- **Merge trunk into the PR's branch** (merge, never rebase) when "Trunk since the review" calls for
  it, run the project's checks and full test suite on the result, and push it.
- **Bring a stacked PR up to date once its base merges.** When the PR was based on another PR's
  branch and that PR squash-merged, GitHub retargets this one to trunk. Trunk's history then holds
  none of the base PR's commits, so a plain merge silently keeps the branch's older copies of the
  base PR's lines wherever trunk's final version doesn't overlap them, with no conflict to warn.
  So merge trunk with `uv run <skill-base-dir>/scripts/rebuild_stacked.py --base-pr-head <sha>`,
  giving the base PR's final head as GitHub lists it. It rebuilds every file the merge touched as
  trunk plus the branch's own diff, and fails unless the staged tree is exactly that. Resolve any
  conflict it lists, keeping trunk's version of the base PR's text and the branch's own additions,
  then rerun it with `--check-only` until it passes. A file it still flags is a conflict that
  needs a judgement about intent.
- **Fix a check failure the trunk merge caused** when the fix is mechanical, such as formatting,
  import order or a lockfile resync, and push it.
- **Wait for checks that are still running.** While the gate reports only waiting conditions
  (exit 3), schedule the next `--check-only` about 5 minutes out, as the rollout watch does, and
  report what each run found.
- **Rerun a check once** when it failed for a reason outside the code, such as a lost runner or a
  registry timeout, and say so.
- **Merge through the gate** once it reports ready.
- **Watch the rollout and run the proof.**
- **Post the report and its PR link,** as "Posting the report" describes.
- **Close the ticket** once every ideal-state bullet of the ticket has a proven verdict on it, from
  this PR or another that names it, every measured effect is within its range or better, and the
  production watch, if this skill offers one, is declined or ends "The time is up" with no new
  warning or error. Any other close waits for the user's choice in "The epilogue".
- **Find what the backlog needs,** as "Updating the backlog" describes. Its changes wait for the
  user's approval.
- **Send the epilogue's Slack message** to the channel in `$PRIVATE_SLACK_REPORT_CHANNEL`, as "The
  epilogue" describes, after invoking `use-slack`. Slack is for work only: where the variable is not
  set, nothing is sent or drafted, and the final message's summary is the whole report to the user.

**An approval holds.** A push to an approved PR never undoes its approval, whatever the push
changes. Never tell the user an approval is stale, and never ask for a new one. A change request
is not an approval: it stands until the reviewer who made it reviews again, so asking them to
re-review is settling their request, not renewing anyone's approval.

**Stop and discuss when:**

- a review finding is unaddressed and the reviewer didn't mark it optional
- a reviewer's latest review requests changes
- a check fails for a reason in the code that is not mechanical
- merging trunk conflicts in a way that needs a judgement about intent
- a live observation the merge relies on no longer holds
- an ideal-state bullet of the PR's ticket is met by no PR, merged or open
- the gate or GitHub refuses for any reason not listed under "Do these yourself"
- verifying would need a change to a deployed environment beyond the normal deploy
- a post to a public destination holds something that looks private, as "Posting the report"
  describes
- `use-jira`'s check cannot run, or a post needs a fix that adds, drops, changes or reorders a word,
  such as a label for a URL, or a fix the check did not print. Post nothing: show the draft and the
  check's output, and wait

**Never roll back, revert or change anything in a deployed environment yourself,** in the rollout
watch or the production watch. Say what you would do and wait for the user.

**Still ask before** watching production and removing branches. Each keeps the approval its section
describes.

## What to work out first

One sentence naming the PR is enough. Get the rest from the environment, and ask the user only for
what none of it holds, such as a credential only they can refresh.

- **The merge commit,** from the PR.
- **The ticket,** from a Jira key in the PR's branch, title or body, or an issue it closes. A PR
  that names more than one is on the ticket whose ideal state it delivers, which its branch name
  or a link alone doesn't decide: read each, and ask the user when two fit. A PR with none has no
  ticket; say so.
- **The claim to prove:** the ticket's properties, plus each side effect the PR's review named, plus
  each behaviour a commit pushed after the latest approval added. Trace each part to the property,
  comment or commit it came from.
- **The expected effects:** for each outcome the change sets out to move, such as a latency, an
  error rate or a memory figure, the expected range, the query that measures it and its baseline,
  from the design's "Expected effect" subsection or the ticket. An outcome the PR or ticket promises
  with no range is still measured; the report says no range was set. For a PR that already merged,
  where the baseline was never taken, read it from records older than the deploy, such as logs,
  when they hold the query's answer, and say so in the report; otherwise the row says no baseline
  was taken.
- **The deploy chain,** from the docs of the repo and of every repo the deploy passes through, such
  as a GitOps repo: each stage between the merge and the running service, and how to read what is
  serving at the end. If the docs don't say how to read what is serving, stop and say what is
  missing. If the merge changed nothing that deploys, say so and why, skip the watch, and go
  straight to the proof.

## Merging

Before merging, report each check that takes judgement, with its result:

- **Trunk since the review:** the commits trunk gained since the PR's head was reviewed, the files
  both sides changed, and whether any of them, or a migration or dependency change on either side,
  could break what the PR relies on. If so, merge trunk into the branch yourself (merge, never
  rebase), run its checks again and push, before merging.
- **Review findings and unresolved threads:** each one, with the commit or reply that addressed it,
  or "not addressed". Unresolved threads are normal here. A finding blocks only when nothing
  addressed it and the reviewer didn't mark it optional, a nit or non-blocking; list the rest
  without blocking on them.
- **The ticket's ideal state:** read the ticket's description and list each ideal-state bullet,
  with what meets it: this PR, an already-merged PR, or a named PR still open. A bullet nothing
  meets stops the merge, under "Stop and discuss", so the PR can meet it before it merges. The
  claim to prove is built from this list.
- **Live observations the merge relies on:** any claim about a live system the PR's design or its
  merge depends on, such as a claim in a token, a header, a config value or a response shape. Run
  each again now on that exact artifact (which token, which endpoint, which host). An observation
  of a neighbouring artifact, such as one environment's value in place of another's, is not
  evidence, however closely the two seem to match.
- **The plan, for a change an infrastructure tool applies on merge,** such as Terraform: read the
  plan for the exact head you are about to merge, and compare it resource by resource with the plan
  the reviewers read and with the PR's description. Explain every difference before merging. A
  difference nobody can explain is a live observation that no longer holds. A branch behind trunk
  can plan trunk's newer infrastructure changes as reverts, so read the plan after trunk is merged
  in. How to read the stack's plans and runs comes from the repo's docs.
- **The baseline for each expected effect:** a production reading taken with the query the
  after-measurement will use, repeated enough to show its noise. One recorded on the ticket or in
  the design counts when its query and environment match. Otherwise take it now with
  `prove-it-works`, since the deploy will erase it. When no production signal can measure the
  outcome, say so: the after-measurement will have nothing to compare with, and the report says
  that.
- **The repo's merge-time steps:** anything its docs say must happen before or after a merge, such
  as running a migration before the deploy reaches it.
- **Timing:** whether another PR has to land first, or anything else makes now the wrong moment. A
  PR stacked on another merges only once the base PR's watch has ended in "Serving", since its own
  plan or build is read against what the base left behind.

When a check needs one of the steps under "Do these yourself", take it and carry on. Stop and say
what would fix it only for a problem under "Stop and discuss". Where the claim's before state will
be gone once the deploy lands, observe it now with `prove-it-works`, in the merge's evidence folder
once you know the merge commit, or under the PR's head commit until then.

Then merge through the gate, passing the full head commit you checked:

```sh
uv run <skill-base-dir>/scripts/merge.py <pr> --repo <owner>/<repo> --head <sha> [--check-only]
```

It refuses unless the head is unchanged, the PR is open and not a draft, someone approved the PR (on
any commit) or it is the repo owner's own PR and the owner is merging it, there is no outstanding
change request, every check on the head passed (a head with no checks passes only when none of the
repo's last 5 merged PRs ran a check either) and GitHub says it can merge. It prints every failed
condition at once. Exit 3 means the only conditions left are waits, such as checks still running:
schedule the next check rather than stopping. Never merge any other way: not `gh pr merge`, not the
button in a browser. `--check-only` reports readiness without merging, for showing the user before
you ask.

## Watching the rollout

**Serving** means the live artifact (a revision, an image digest, the tag that digest carries) was
built from the merge commit or from a later trunk commit that contains it, as GitHub's compare of
the two says. A run's status, a pipeline's "success" or a health badge never counts. Name the
artifact you read.

A change an infrastructure tool applies builds no artifact. There, serving means that in every
stack the merge touches, the apply run on the merge commit, or on a later trunk commit that
contains it, finished, and the resources it changed match the plan read before merging, as direct
queries of the live system show. Name each run and the queries.

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

- **Serving,** with the artifact and the compare that shows it contains the merge, or for an
  infrastructure apply, the run and the live queries that show its resources match its plan.
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
evidence folder. Write the report: the PR, merge commit and ticket, the claim and where
each part came from, the rollout from merge to its ending, and the `prove-it-works` report
unchanged except for any reference to the local evidence folder, which teammates cannot open: drop
the line naming the folder, and each file name cited from it. Change nothing in any deployed
environment.

For each expected effect, run the baseline's query again, as many times as the baseline ran, and
add a "Measured effect" table to the report, one row per outcome: the baseline, the result, the
delta, the expected range, the gap between the estimate and the result, and one verdict:

- *within range*;
- *better than expected*: improved past the range;
- *short of expected*: improved, but less than the range;
- *regression*: moved the wrong way from the baseline.

An outcome with no range takes *improved*, *unchanged* or *regression* from its direction against
the baseline, and the row says no range was set. A row outside the range
carries the explanation found for it, after checking the measurement first (same query, same
conditions, enough runs to see the noise, the right build serving) and then reading finer signals,
such as per-step timings, to find where the difference came from. A row without an explanation
says so. Where noise in steps the change does not touch hides its effect, measure the change's own
step, or alternate runs with and without the change's path, and say which was done.

Whatever the verdicts, the report is finished and posted: a disproved or unobservable part of the
claim is a fact to record, not a reason to hold it back. "The epilogue" then decides what follows.

## Watching production

Where the change is serving and the proof proved every part of the claim, offer in the final
message to watch production, and ask for how long.
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
went to, and post it as "Posting the report" describes, without a second PR link. Only "The time is
up" with no new warning or error lets the ticket close. After either other ending, leave the ticket
open and say why in the final message.

The watch only reports, as the rule under "What invoking this skill approves" requires.

## Posting the report

The report goes on the ticket it proves: a Jira issue, or a GitHub issue. A PR with neither gets
the report on the PR. Post it without asking once the proof has run, whatever its verdicts,
because invoking this skill approves it. The final message quotes what was posted and links to it.

Before posting, check the report, and later the watch's summary, for credentials (tokens, keys,
cookies, bearer headers, signed URLs) and for references to the local evidence folder. Remove any
you find, and say so in the post.

Every post this skill makes gets the next check, judged by that post's own destination: the
report, the PR link, the closing comment, the watch's summary and each backlog change the user
approves. When the destination is public,
such as an issue or PR in a repo whose `gh repo view <owner>/<repo> --json visibility` says
`PUBLIC`, check the post for private values. Search it for each `PRIVATE_*` value in the dotfiles
repo's ignored `private.env` (`~/Repos/ooloth/dotfiles/private.env`), and for each value in the
PR repo's own ignored `private.env` if it has one. Remove any match and say so in the report. On a
public PR, the link to a Jira ticket names the key only, never its URL. If anything else in a post
looks private, such as an internal hostname or URL, or a person's name or handle that the ticket
does not already show, post nothing and show the user the draft.

- **Jira:** post the comment with the Atlassian MCP tool, following `use-jira` for how markdown
  converts. When the MCP server will not connect, post it with acli as an ADF body, as `use-jira`
  describes.
- **A GitHub issue or PR:** post with `gh issue comment` or `gh pr comment` from a file, following
  `use-gh`.
- **The PR link:** once the ticket comment exists, post one line on the PR linking to it.

Screenshots and recordings are not uploaded, and the posted report does not name their local
paths. It describes what each one shows.

Then list every ideal-state bullet of the ticket, with the PR and the posted report that prove it.
Only when every bullet has one, and every measured effect is within its range or better, can the
ticket close without asking, with a closing comment saying which PRs finished it. A bullet without
one keeps the ticket open, and the final message names it. A measured effect short of its range, or
a regression, means the ideal state the ticket targeted was not reached, so "The epilogue" asks the
user how the ticket ends. When this
run offers a production watch, the ticket waits for the user's answer to that offer: it closes once
they decline it, or once the watch ends "The time is up" with no new warning or error and its
summary is posted. When no watch is offered, because nothing deploys, it closes now.

## Updating the backlog

Once the report is posted, run `wrap-up-backlog` on what this PR shipped: the PR, its commits,
its ticket and the decisions it settled. Post none of it yourself, because a change to another
ticket notifies the people watching it. Put its list in the final message as one numbered list:

- **Each fix** as it would be posted: the comment, the description rewrite, the relationship
  change, or the closing of a ticket this change finished, with a comment saying what finished it.
  A bare "yes" to a fix posts it as shown.
- **Each ask** as a question with its lettered options and its recommendation.

None of them blocks anything: the change has shipped, and the backlog can wait for the user's
answer. Once the user answers, post what they approved, and list every ticket changed with a link
to each.

## The epilogue

Once the report is posted, the final message opens with a short summary: each part of the claim
with its verdict, and the "Measured effect" table, so the user sees the deltas without opening the
ticket. Then exactly one of these follows, chosen from the report by the first that applies:

- **Something broken:** a disproved part of the claim, or a measured effect that regressed. The
  ticket stays open. Offer two paths and wait for the user's choice: revert, or a follow-up fix
  through `write-ticket-description`. A revert is the user's decision, never taken by this skill, as
  above. Then send a Slack message, written for the team, saying what was learned and what happens
  next: a ticket when the fix is known, or a call for discussion when it is not.
- **The target not reached:** a measured effect short of its range, or a part of the claim the proof
  could not observe. The ideal state the ticket targeted was not shown, so ask the user how the
  ticket ends, and act on the answer: (a) close it as close enough, with a closing comment that
  names the gap; (b) keep it open, and draft a follow-up task or a subtask of the ticket through
  `write-ticket-description`, holding what the measurement showed and the gap it leaves; or (c)
  close it as not achievable, with a closing comment giving the reasoning. Where an ideal-state
  bullet still waits on another PR, the ticket stays open whatever the answer, and the answer is
  posted as a comment so it is applied when that PR's proof closes the ticket. A measured effect
  within its range or better is still announced in Slack, with the gap named.
- **Everything proven, and each measured effect within its range or better.** The ticket closes as
  "Posting the report" describes. Send a short Slack message announcing the result: what changed
  for users, the before and after numbers, and links to the PR and the report. A result better than
  expected gives the report's explanation, or says none was found.

Every Slack message is sent only after the report is posted, links to it, and carries no figure the
report does not. It goes to the channel in `$PRIVATE_SLACK_REPORT_CHANNEL`, the user's own, from
which they forward what they choose. Where that variable is not set, no Slack message is sent or
drafted: Slack is for work only, and the final message's summary carries the result.

## Cleaning up

Only after a "serving" ending with a proven verdict, offer to remove the PR's leftover local
branches and worktrees, in every clone and worktree of the repo on this machine. A branch qualifies
only when its tip is one of the PR's own commits, as GitHub lists them for the PR, so trunk and
branches resting on older trunk commits never match. A worktree qualifies when its checked-out
branch does. Never offer:

- a worktree with uncommitted or untracked files
- a worktree a running session, terminal tab or process has open
- the main checkout of a repo, even on the PR's branch: say it would need to switch to the default
  branch first
- a branch another open PR is based on

List each candidate with why it qualifies, and each one you left out with why. Remove only what the
user confirms, with `git worktree remove` and then `git branch -D`, never by deleting folders.
`-D` is needed because a squash merge leaves the branch's commits out of trunk, so `-d` always
refuses; the check above, that the tip is one of the PR's own commits, is what makes it safe.

Once the last report of the run is posted, offer to delete the merge's evidence folder,
`~/Repos/agents/prove-it-works/<owner>-<repo>/<merge commit>/`, and the PR head commit's folder
there if the before state was saved in it. The last report is the production watch's summary when
the user accepts a watch, and the proof's once they decline one or none is offered, so while a watch
offer waits for its answer, this offer waits too. The posted reports are the record people read, and
nothing reads the raw files afterwards. Offer it with the same "serving" and proven condition as
the branches, because a failed or unproven change is debugged from those files. Delete the folders
only when the user confirms, and never while a watch still writes to them.
