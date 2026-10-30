---
name: monitor-prs
description: Check every few minutes for pull requests where it is the user's move, and say why each one is waiting on them. Read-only for now. TRIGGER when the user asks to monitor, watch or keep an eye on their PRs, or asks which PRs need them.
argument-hint: 'Optional: "stop" to end monitoring'
---

Input: $ARGUMENTS

If the input is "stop", delete every pending job whose prompt is `/monitor-prs` (`CronList`, then
`CronDelete`), say that monitoring has stopped, and do nothing else.

Otherwise run one check, report it, and schedule the next one. A check is read-only: it never
writes to GitHub (no comments, reviews, merges, labels or mutations) and never opens a session,
tab or window.

## Which pull requests

"Me" is the account `gh api user -q .login` returns. Read three searches, all open pull requests in
unarchived repositories, drafts included:

- **Mine:** `author:@me`
- **Asked of me by name:** `user-review-requested:@me`
- **Asked of one of my teams:** `review-requested:@me`, only in the repositories listed one
  `owner/name` per line in `team-repos.local` in this skill's base directory. That file is
  untracked, because the list names work repositories and this repository is public. If it is
  missing or empty, skip this search and say so in the report.

GitHub search returns nothing, with no error, for a repository that does not exist or that I cannot
see. So on the first check in a session, confirm each listed repository with
`gh api repos/<owner>/<name> -q .full_name` and name any that fail in the report.

## Reading them

Make one `gh api graphql` request that runs all three searches as aliases, and write its response
to a file in a new directory from `mktemp -d`. Read the file with `jq` and never print the raw
response: it is tens of kilobytes, and other people's comment text has no place in this session.
For each pull request ask for: number, title, url, createdAt, isDraft, headRefOid, reviewDecision,
mergeStateStatus, repository name, author login, the last commit's statusCheckRollup state,
reviewRequests (requested reviewer's `__typename` and login), latestOpinionatedReviews (id, state,
submittedAt, author), the last 50 reviews (id, state, body, submittedAt, author), the last 50
top-level comments (id, createdAt, author), and the last 50 reviewThreads (totalCount, isResolved,
and each thread's last 10 comments with id, createdAt and author). Ask for `__typename` and `login`
on every author so a bot can be told from a person. Do not ask for a team's slug: it needs a scope
the token may lack, and the whole query then fails.

A pull request found by more than one search is one pull request, and is decided and listed once.

Before reading any turn, check the response is complete:

- A failed request is a failed check. Report it with the error and schedule the next check.
- An `errors` array means some of it is missing. Name what the errors say is missing.
- A search whose `issueCount` is larger than the nodes it returned is truncated. Say so and how many
  were left out.
- A pull request whose reviewThreads `totalCount` is above 50 was only partly read. Say so beside
  it.

Never report "nothing waiting" from a response that is incomplete in any of these ways.

## Whose move it is

Decide from this one response alone. Nothing from an earlier check decides a turn.

Someone else's pull request that asks for my review, by name or through a listed team's search, is
**review requested** unless it is a draft, in which case it is not my move.

For my own pull request, the first of these that holds is the reason:

1. **Feedback**, when any of these holds, naming whoever left the newest of them:
   - an unresolved thread whose newest comment is not mine. A bot's counts.
   - a reviewer whose latest verdict is changes requested and whose review is not requested again.
     A team being requested does not count as asking that reviewer again.
   - a review with a non-empty body, from a person rather than a bot, in state approved, changes
     requested or commented, that is newer than my newest review or top-level comment. My replies
     inside threads do not count here.
2. **Checks failing**, when the rollup is FAILURE or ERROR.
3. **Draft**, when it is a draft.
4. When it is approved: reviewDecision is APPROVED, or reviewDecision is empty and the latest
   verdicts include an approval and no changes requested.
   - mergeStateStatus CLEAN, UNSTABLE, HAS_HOOKS or BEHIND: **ready to merge**.
   - BLOCKED while the rollup is PENDING or EXPECTED: **ready to merge**.
   - DIRTY: **conflicts**.
   - UNKNOWN, DRAFT or anything else: **undecided**, because GitHub has not worked out whether it
     can merge. Not a turn.
   - BLOCKED otherwise: carry on as if it were not approved.
5. **Not my move** when someone else holds it: any review is requested (a person, a bot or a team),
   or an unresolved thread ends with my comment and a person other than me commented in its last 10.
6. **No reviewer** otherwise.

Agents act under my account, so their comments count as mine. That is a known limit, not something
to work around.

## Reporting

Give each turn a key: `owner/name#number:reason:headRefOid`, followed for feedback by
`:<id of the newest comment or review that made it feedback>`. The reason in a key is spelled
exactly one of `feedback`, `checks-failing`, `review-requested`, `conflicts`, `ready-to-merge`,
`draft` or `no-reviewer`. Where several items share the newest timestamp, the newest is the one
that comes last in the response. Keys are compared between checks, so the same state must always
give the same key.

Report turns in this order, oldest first within each reason: feedback, checks failing, review
requested, conflicts, ready to merge, draft, no reviewer. One line each: reason, `owner/name#n`,
title, url, key. Give no count of turns: the list is the count, and a number written beside it can
disagree with it. After the list, give one line naming the pull requests that are not my move, then
name any undecided pull requests, anything incomplete, any team repository that failed its check,
and when the next check runs.

When every key matches the previous check in this session and nothing is incomplete, report one
line instead, such as "No change since 14:05. Next check 14:35."

## Scheduling the next check

Delete the `mktemp -d` directory once the report is written. It holds other people's comment text,
and a directory left behind by every check would collect it.

End every check, a failed one included, by making sure exactly one check is pending. Look at the
pending jobs with `CronList`. If one already has the prompt `/monitor-prs`, leave it. Otherwise
create a one-shot job (`recurring: false`) with `CronCreate` whose prompt is `/monitor-prs`, then
end the turn so the report reaches the user and the session is free in between.

Pick the time: about 15 minutes out, or about 5 when one of my pull requests has checks running
(its rollup is PENDING or EXPECTED) or is undecided. Avoid minutes 0 and 30. Where `CronCreate`
does not exist, say that monitoring cannot continue in this session and stop.

The first report in a session also says that checks run only while this session stays open and
idle, and that `/monitor-prs stop` ends them.
