---
name: monitor-prs
description: Check every few minutes for pull requests where it is the user's move, ranked by what to deal with first, with the next step for each, and open a session that drafts replies and fixes for new feedback on the user's own pull requests. Never writes to GitHub. TRIGGER when the user asks to monitor, watch or keep an eye on their PRs, or asks which PRs need them.
argument-hint: 'Optional: "stop" to end monitoring'
---

Input: $ARGUMENTS

If the input is "stop", delete every pending job whose prompt is `/monitor-prs` (`CronList`, then
`CronDelete`), say that monitoring has stopped, and do nothing else.

Otherwise run one check, report it, and schedule the next one. A check never writes to GitHub (no
comments, reviews, merges, labels or mutations). Its only writes are the ones "Preparing feedback"
describes: a fetch, a worktree and a tab for each pull request it prepares.

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
For each pull request ask for: number, title, url, createdAt, isDraft, headRefName, reviewDecision,
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

My pull request **has feedback** when any of these holds:

- an unresolved thread whose newest comment is not mine. A bot's counts.
- a reviewer whose latest verdict is changes requested and whose review is not requested again. A
  team being requested does not count as asking that reviewer again.
- a review with a non-empty body, from a person rather than a bot, in state approved, changes
  requested or commented, that is newer than my newest review or top-level comment. My replies
  inside threads do not count here.
- a top-level comment from a review bot that is newer than my newest review or top-level comment.
  A review bot is one whose login is a key of `BOT_NAMES` in
  `../review-pr-comments-converge/scripts/fetch_pr_comments.py`, relative to this skill's base
  directory. Such a bot posts its whole review as one comment, outside GitHub's reviews.

For my own pull request, the first of these that holds is the reason:

1. **Approved**, when reviewDecision is APPROVED, or reviewDecision is empty and the latest verdicts
   include an approval and no changes requested. mergeStateStatus decides what is left to do:
   - CLEAN, UNSTABLE, HAS_HOOKS, BEHIND or DIRTY, or BLOCKED while the rollup is PENDING, EXPECTED,
     FAILURE or ERROR: approved, with its preparation named in the next step (see Reporting).
   - BLOCKED otherwise: carry on to the next reason as if it were not approved, because something
     other than its checks blocks it, such as a missing approval.
   - UNKNOWN, DRAFT or anything else: **undecided**, because GitHub has not worked out whether it
     can merge. Not a turn.
2. **Feedback**, when it has feedback.
3. **Draft**, when it is a draft.
4. **Checks failing**, when the rollup is FAILURE or ERROR.
5. **Not my move** when someone else holds it: any review is requested (a person, a bot or a team),
   or an unresolved thread ends with my comment and a person other than me commented in its last 10.
6. **No reviewer** otherwise.

Agents act under my account, so their comments count as mine. That is a known limit, not something
to work around.

## Preparing feedback

Each of my pull requests whose next step includes "Reply to feedback" gets a session that runs
`review-pr-comments-converge` on it, so its report is waiting when I look. Prepare only in Rex:
when `TMUX` is set or `REX_SESSION` is not, prepare nothing and say so above the table.

List the tabs of the session labelled `Workers` once per check, with
`rex window ls -s Workers --json`, whose labels are at `.windows[].label`. When there is no
`Workers` session, no tab is open. A pull request's tab is
`PR <number> (<author login>): review-pr-comments-converge`, and a prepared session is any open tab
whose label ends in `: review-pr-comments-converge`. Then take each such pull request in table
order:

- **Its tab is open:** prepare nothing. The tab is the record that this feedback is being prepared,
  and nothing else records it.
- **3 prepared sessions are open,** counting the ones this check opened: prepare nothing, and list
  the pull request above the table as waiting for a free tab.
- **Otherwise,** prepare it in these steps, from my clone at `~/Repos/<owner>/<name>`:
  1. Check that `git -C <clone> remote get-url origin` ends in `<owner>/<name>` or
     `<owner>/<name>.git`. A clone that is missing, or whose origin is another repo, is never used.
  2. `git -C <clone> fetch origin <headRefName>`.
  3. Add a worktree on its own branch, where `<time>` is the UTC time with no separators, such as
     `20261101T2200Z`. A new worktree on its own branch means the session never works in a
     checkout I might be using.

     ```sh
     git -C <clone> worktree add --track -b pr-<number>-<time> \
       <clone>/.claude/worktrees/pr-<number>-<time> origin/<headRefName>
     ```

  4. Open the tab, and confirm with `jq -e .window_id` that Rex returned it:

     ```sh
     bash ~/Repos/ooloth/dotfiles/tools/rex/claude-tab.bash '<tab>' <worktree> \
       '/review-pr-comments-converge <owner>/<name>#<number>'
     ```

  When a step fails, stop preparing that pull request and say above the table which one, which
  step, and the error, quoted. The next check tries again. When the launch fails after the worktree
  was added, remove both first, with `git -C <clone> worktree remove <worktree>` and then
  `git -C <clone> branch -D pr-<number>-<time>`, so failed tries don't pile up.

## Reporting

A report states what is true now and nothing else. It keeps nothing between checks and compares
nothing with an earlier one, so every report lists every pull request the searches found.

Report them in one table, sorted so that the turn to deal with first is row 1 and the pull requests
that are not my move come last. Rank by these tiers, top first, and within a tier put the pull
request opened earliest first, comparing the whole `createdAt` timestamp and not only its date:

1. Approved.
2. Review requested, on a pull request opened 30 days or less before the check.
3. Feedback.
4. Checks failing.
5. No reviewer.
6. Draft.
7. Review requested, on a pull request opened more than 30 days before the check, because a request
   left that long has more likely been abandoned than kept waiting on me.
8. Not my move, which includes someone else's draft that asks for my review. These rows need
   nothing from me; they are listed so the table shows every pull request that involves me, with
   who holds each one.

The table has these columns:

- **#**: the row number, from 1, so I can name a row by it.
- **Next step**: what I do next.
  - **Approved:** every step that applies, in this order, then "merge": "Resolve conflicts" when
    DIRTY, "Update branch" when BEHIND, "Fix checks" when the rollup is FAILURE or ERROR, and
    "Reply to feedback" when it has feedback. So "Merge" alone, or "Fix checks, then merge". When
    the rollup is PENDING or EXPECTED and nothing else applies, "Merge once checks pass".
  - **Review requested:** "Review", or "Review, or ask if still needed" in tier 7.
  - **Feedback:** "Reply to feedback".
  - **Draft:** "Make it reviewable", or "Fix checks, then make it reviewable" when the rollup is
    FAILURE or ERROR.
  - **Checks failing:** "Fix checks".
  - **No reviewer:** "Request a reviewer".
  - **Not my move:** "Wait for a review" when a review is requested, "Wait for a reply" when an
    unresolved thread ends with my comment, and "Wait until it's out of draft" for someone else's
    draft.
- **Author**: the author's login, on every row, mine included.
- **Title**, in full. The table wraps a long cell, so a title is never cut short.
- **Note**: when it has feedback, who left the newest of it and how many unresolved threads do not
  end with my comment, such as "Copilot, 4 unresolved threads" or "alice requested changes". When
  its prepared session's tab is open, the Note ends with "report in" and the tab's name. Name
  authors and count things only; never quote or summarise what a comment says. For review
  requested, the date the pull request was opened, such as "opened Jun 24". For not my move, who
  holds it: each requested person or bot by login, and each requested team as "a team" or "two
  teams" and so on, since a team's name is not read, such as "alice, bob, a team"; or the
  person whose reply a thread waits on. Otherwise empty.
- **Link**: the pull request's `url` field, copied from the response rather than built from the
  repository name, and bare rather than a markdown link, because the terminal prints a markdown
  link's url beside its text.

Above the table, one line each: any undecided pull requests, anything incomplete, any team
repository that failed its check, each pull request waiting for a free tab, each one that could not
be prepared, a note that nothing is prepared outside Rex, and when the next check runs. Name each
pull request there as `name#n`, with the repository's full name less its owner, such as
`example-data-pipeline#231`. Give no count of turns: the table is the count, and a number written
beside it can disagree with it. The reply ends with the table, followed only by any
numbered questions for me.

While checks are pending in a session, every reply ends this way, not only the scheduled checks. A
reply that is not a scheduled check first reads GitHub as a check does, so its table is current,
and leaves the pending check as it is.

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
