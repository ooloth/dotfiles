---
number: 010
status: accepted
date: 2026-11-02
---

# 010 — An open tab is the only record of what monitor-prs has prepared

## Forced by

`monitor-prs` opens a session that runs `review-pr-comments-converge` for each of my pull requests
with feedback (#224), and checks again every 5 to 15 minutes. Without a record of what it has
prepared, every check would open another session on the same feedback. #221 lists where that record
is kept as an open question, because it is a new piece of persistent state. #224's
[approach comment](https://github.com/ooloth/dotfiles/issues/224#issuecomment-6563647978) scored
the options, and this record settles the question there.

The record also has to follow
[ooloth/hub 030](https://github.com/ooloth/hub/blob/main/docs/decisions/030-whether-a-pull-request-is-my-turn-is-read-from-its-state-in-one-refresh.md),
which #221 names as a constraint: whose turn a pull request is comes from one snapshot, never from
what an earlier check saw.

## Decision

A pull request counts as prepared exactly while a Rex tab labelled
`PR <number> (<author>): review-pr-comments-converge` is open, in any Rex session. Each check lists
every session's tabs once and skips a pull request whose tab is open. Nothing else is stored.
Closing the tab without answering the feedback makes the next check prepare the pull request again,
which is right, because it is still my move. When the tabs cannot be listed, the check prepares
nothing. `monitor-prs/SKILL.md` and `monitor-prs/scripts/prepare_feedback_session.py` hold the
rules.

## Rejected

- **A stored record of prepared feedback, written and read by a tested script.** It could survive a
  closed tab, and could key on the newest feedback's ID, so closing a tab without acting would not
  bring the same feedback back. It is rejected because it has to be kept in step with what is
  actually open, and it fails silently when it is not: a stale entry, such as one left by a session
  that crashed, keeps a pull request from ever being prepared again, with nothing in any report to
  say so. Reading the open tabs reads what is true now, as hub 030 asks. It reverses if closing a
  tab without acting turns out to be common enough that re-preparing becomes a burden.
- **Not yet: no record, so every check prepares every pull request with feedback.** It needs no
  state at all. It is rejected because the next check, at most 15 minutes later, would open a
  second session on feedback the first is still drafting replies to, and both could push to the
  same head.

## Risk

- **Same number in two repos:** a label names no repo, so while `hub#88` has an open tab,
  `dotfiles#88` is skipped and its Note names the other repo's tab. Labels stay short in the
  sidebar, and I accepted that risk in the review of `ac165c1b..99c7bee1`.
- **Sessions with no matching tab:** a session started in a plain terminal, or in a tab named some
  other way, has no matching label, so `monitor-prs` prepares a second session beside it. The check
  before posting in `review-pr-comments-converge` then shows each session the other's replies
  before it posts.
- **Tabs closed without acting:** each such close costs a fresh session the next time feedback is
  waiting.

## Revisit when

A pull request has two prepared sessions open at once, a report names another repo's tab for a pull
request, or I close prepared tabs without acting often enough that the sessions they reopen are
noise.

## Also update

- [ ] #221 — tick the open question about where the record of prepared turns is kept, linking this
  record
- [ ] #224 — a comment saying the preparation steps are now a script and prepared sessions run
  with `--unattended`
