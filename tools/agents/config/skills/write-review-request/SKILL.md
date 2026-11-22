---
name: write-review-request
description: Draft one Slack message per channel asking for reviews of the user's open work PRs, ranked by cost of delay, tagging the user's own team. Use when the user asks for a review request, or to ask people to review their PRs. Shows the drafts for approval, then posts them only to the user's own channel for them to copy where they belong.
---

# Write a review request

A reviewer should be able to tell from the message alone which PRs need their review and, on the
user's own team, that the order is the priority. Everything below serves that, in as few lines as
it takes.

Before step 1, read the `use-slack` skill and run its "Work only" check. When it fails, say so and
stop, because step 2 depends on Slack. Read `use-gh` before the first `gh` command and `use-slack`
again before each Slack call.

## 1. Find the PRs waiting on reviewers

List the user's open PRs in the work GitHub org only, then read each one, keeping only the paths
from `files`. `gh search prs` lacks most of these fields, such as `mergeStateStatus` and
`latestReviews`, so each PR needs its own `gh pr view`:

```bash
gh search prs --author @me --owner recursionpharma --state open --json url,isDraft --limit 100
gh pr view <url> --json isDraft,mergeStateStatus,statusCheckRollup,reviewRequests,\
latestReviews,baseRefName,additions,deletions,body,files
```

The user never asks colleagues to review PRs in their own `ooloth` org, so those are never read,
shown or mentioned. Drafts go in no message, and the table in step 4 lists them as left out.

Every PR needs an approval from a person on each team that owns its code: always the user's own
team, whose members the user's earlier requests tag, plus the teams the repo's `CODEOWNERS` names
for the changed files and any team requested on the PR. Read each repo's `CODEOWNERS` once, from
the PR's base branch. A PR goes in the request for each owning team that has not approved it yet.

An approval counts for a team only when its author is a member of that team. Read each owning
team's members once with `gh api --paginate orgs/recursionpharma/teams/<slug>/members -q
'.[].login'`, asking the user, in step 2's message, for any team's slug you cannot find, such as
the user's own team's. A bot is never a member, so a bot's review counts for nothing. When a
membership read fails, that team has not approved, and the table says its membership could not be
read.
`reviewDecision` does not decide this, because it can read empty on an approved PR and does not say
which team an approver is on. A PR every owning team has approved is left out, with its reason, for
the terminal (step 4).

Then note, for the terminal and the offer after posting:

- **Checks failing:** a PR with a check in `statusCheckRollup` whose `conclusion` is `FAILURE`,
  `TIMED_OUT`, `CANCELLED`, `STARTUP_FAILURE` or `ACTION_REQUIRED`, or whose `state` is `FAILURE`
  or `ERROR`, still goes in, and is warned about.
- **Conflicts:** a PR whose `mergeStateStatus` is `DIRTY` still goes in, and is flagged. GitHub
  computes it lazily, so read it again once when it is `UNKNOWN`.

## 2. Match each PR to a team

Find the user's earlier review requests: messages from the user, outside the two scratchpads
`use-slack` names, that list PR links and ask for review, newest first. A request to the user's
own team tags them; one to another team usually tags no one. Read the most recent one in each
channel they appear in, with its thread. Each gives a team: its channel, the people tagged, if
any, and the repos and ticket keys of the PRs it listed.

Each owning team from step 1 that has not approved a PR gets that PR in the message for the
channel it is asked in. Teams asked in the same channel share one message. Match the
user's own team by the people its requests tag and its ticket keys, and another team, such as the
code owners of a shared repo, by its channel and the repos its requests listed. Ask the user, in
one message, which channel each owning team with no earlier request should be asked in, and about
every PR whose owning team is unclear. Never guess a team.

## 3. Rank each team's PRs

Order each team's PRs by cost of delay to ship and verify: what waiting costs each day the PR is
unmerged, highest first. Weigh:

- what users see: a change to what users see or get back ranks highest when it must land before a
  date after which it should stop shifting, such as a launch to new users who would otherwise see
  their results change under them. It outranks performance and reliability wins in the same list
- the harm each day without it, such as a user-facing bug, then a deadline it is needed for
- what it unblocks: a PR other PRs are stacked on, or that later work waits for
- how long verifying it takes after merge, such as an alert or a capacity change that needs a day
  of production data before anyone can call it done, since merging it sooner starts that clock

Docs-only PRs go at the bottom, in any order, since delaying them costs little next to a functional
change. Otherwise size, `additions` plus `deletions`, breaks ties only, smallest first.

Read each PR's body and its ticket for these facts. Which change users would notice, and which
date it must beat, often takes context the PRs do not hold, so ask the user about the top of the
order when the facts do not settle it, and say where a reason is your guess.

Some PRs must merge in a set order: one whose `baseRefName` is another's branch, or one whose
body says it merges after another. They form a series, listed together in merge order and ranked
as one by the cost of delay of finishing the whole series. Where the order inside a series is open,
production goes before other environments.

Look for a deadline that sets the order, such as a demo or a launch, in the team channel's recent
messages and the PRs' tickets. Ask the user when you find none and the
order suggests one.

## 4. Show the drafts

First show one table of every open work PR, drafts included, so the user can check what counts as
their PRs before reading any draft. One row per PR, in each message's order, with these columns:

- **#:** the row number, so the user can say "row 3"
- **PR:** repo and number, linked
- **Ticket:** the PR's ticket keys, each linked, or blank when it has none
- **Waiting on:** each owning team that has not approved it, with the team's message and the PR's
  position there, or "left out" and why
- **Why here:** one line on why it ranks at that position, saying where the reason is a guess
- **Flags:** "merge after" a row number, or a PR when that PR is not in the table; conflicts;
  failing checks

Then, for each channel: the channel the message is for, and the draft in the shape below, written to
a file and checked for mentions as `use-slack` describes before it is shown. A team
with no PRs waiting gets no draft, and the terminal says so. Say that the approved drafts will be
posted to the user's own channel, and ask the user to approve, reorder, cut or reword.

The user's own team:

```
<@U…> <@U…> PRs needing your reviews today (in priority order): :pray:
1. [PR title as written](url) - _<series> 1/2_
2. [PR title as written](url) - _<series> 2/2_
3. [PR title as written](url)
```

Any other team, such as the code owners of a shared repo:

```
A couple <project> PRs that need your team's review. :pray:
1. [PR title as written](url)
2. [PR title as written](url)
```

- The user's own team is tagged once, in the first line, by Slack user ID. Another team's message
  tags no one, since the user posts it in that team's channel.
- Another team's first line is as above, with only its count word varying. "A couple <project>
  PRs that need" becomes "A <project> PR that needs" for one PR and "A few" for more than two.
  `<project>` is the product the PRs change, in the words the user's earlier requests use. Neither
  line counts the PRs exactly, since the numbered list does.
- The link text is the PR title exactly as written, so the reviewer finds the same words in
  GitHub.
- Nothing but the first line and the numbered items: no headings, breaks, notes or footers.
- A PR in a series ends with `- _<series> N/X_` only when the whole series is in this message and
  its title does not already say `N/X`. The `- ` goes outside the italics. It gives its place in
  the merge order and the series' length. The series is named in a few plain words for what it
  changes, such as "search filters", not by a ticket key, which the titles already carry.
- Match the voice of the user's earlier requests in that channel in any line the template leaves
  open.

## 5. Post the approved drafts to the user's own channel

Post each approved draft, unchanged, to the channel whose ID is in `$PRIVATE_SLACK_REPORT_CHANNEL`,
the user's own channel, from which they copy what they choose into each team's channel. Post it
from its file as `use-slack`'s "Posting" describes. Never post to a team's channel or DM anyone.

Then tell the user, for each draft, the team channel it is meant for and its permalink. Offer to
help with each PR that has failing checks or conflicts.
