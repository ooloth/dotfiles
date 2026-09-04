---
opened: 2026-09-04
status: open
resolves_into: decision
---

# How can agents help me notice and clear my PR review queue?

## Why it matters

The goal is to unblock colleagues and notice when they've unblocked me, without leaving someone
blocked for hours or days because I didn't notice their PR or their reply. Two existing systems
were meant to solve this and both went unused:

- `tools/agents/config/skills/review-prs/` — interactive, session-based, scoped to
  `review-requested:ooloth` within the `recursionpharma` org only. Proved clunky; not used in a
  while.
- `~/Repos/ooloth/hub` (the TUI) — meant to be a single prioritized list of everything needing
  attention across GitHub, Linear, logs, etc. Not used in a while, likely because it only fetches
  while open and produces no notification when a new signal arrives.

## What would settle it

A design that:

1. Detects, across one or more repos: new open non-draft PRs, explicit review requests, and
   replies where the ball is back in my court.
2. Pushes a notification when something is detected, so I don't have to remember to check.
3. Optionally does proactive investigation (research the thread, gather relevant facts/evidence,
   propose a candidate reply/action) rather than just itemizing the todo.
4. Supports interactive follow-up when I sit down to clear the queue — e.g. spawning one
   Claude Code session per PR in separate tmux windows (capped at 3 concurrent) for
   review/approve/discuss.

## Resolves into

`../decisions/` once one exists — this repo has no `docs/decisions/` folder yet. The first
decision written from this question would also establish that folder and its format
(see `## Source` below for the pattern being borrowed).

## Source

Discussion on 2026-09-04, prompted by a request to add a "which PRs need my attention" skill to
`tools/agents/config/skills/`. The `docs/questions/` + `docs/decisions/` structure itself is
borrowed from [ooloth/puzzles](https://github.com/ooloth/puzzles/tree/main/docs).

## Options

**A. Extend `hub` with push notifications + background fetching.**
Rejected for now — `hub`'s `docs/decisions/009-no-scheduled-runs.md` and its TUI-refresh decision
explicitly reject scheduled/unattended runs and a daemon; `docs/vision.md` states hub is
deliberately "pull, not push." Adding this reverses two accepted ADRs rather than filling an open
slot. Its GitHub GraphQL query (in `clients/src/github/prs/fetch.rs`) already pulls
`reviewThreads` (with `isResolved`) and comments per PR — useful as a reference for the
reply-detection query shape, independent of whether hub hosts the feature.

**B. Split the problem: a cloud Routine for detection + push, a local skill for interactive
action.** Recommended direction. `tools/claude/config/routines/` already hosts this pattern —
markdown prompts run by Anthropic's cloud Routines feature, triggered on a schedule or GitHub
event (`scan-standards.md`, `implement-ready-issues.md` are existing examples). A routine can
react to GitHub PR/review/comment events directly instead of polling, and push a digest to a
Slack DM (decided — see below) since a cloud routine can't produce a desktop notification
directly but Slack's own desktop notifications can stand in for one. The interactive/tmux-fan-out
piece needs a local terminal session (routines don't have tmux access), so it stays a separate,
manually-invoked skill.

**C. Rely on `/loop` for periodic checking.** Rejected as the primary mechanism — confirmed via
Anthropic's docs (code.claude.com/docs/en/scheduled-tasks) that `/loop` is session-scoped, dies
when the session closes, and only fires while the session is idle. It doesn't solve "notice while
I'm away from the laptop," which is the actual failure mode being addressed. It may still be
useful as an on-demand, manually-started check during a working session.

**D. Extend the existing `review-prs` skill in place vs. build a new skill scoped to "a given
repo."** Undecided. `review-prs` is hardcoded to `user:recursionpharma` and
`review-requested:ooloth` only; the new capability needs to work for a single named repo
(personal or org) and cover new PRs, review requests, and reply detection.

**E. Reply-needed detection strategy.** Two fidelity levels discussed:
- v1 (simpler, start here): eagerly flag every atomic reply where someone else's comment came
  after my last comment/review on that thread.
- Ultimate: reason about whether the ball is actually back in my court using time elapsed and
  conversation content — including prose signals like "look again now" that don't go through
  GitHub's official re-request-review mechanism, since authors often dribble in replies rather
  than batching them.

## Findings

_Findings are working evidence, not settled fact. Nothing here binds a decision until it
graduates into a decision record._

- `/loop`: session-scoped, dies on session close, only fires while idle, forgotten loops
  auto-expire after 7 days, dynamic mode self-paces 1–60 min and can self-stop. Source:
  [code.claude.com/docs/en/scheduled-tasks](https://code.claude.com/docs/en/scheduled-tasks) and
  corroborating web search, 2026-09-04.
- `/schedule` (Routines): cloud-hosted, survives a closed laptop, minimum interval 1 hour, daily
  run cap, supports GitHub event triggers in addition to schedule triggers. Source:
  [claude.com/blog/introducing-routines-in-claude-code](https://claude.com/blog/introducing-routines-in-claude-code)
  and corroborating web search, 2026-09-04.
- `hub` is a 17k-line Rust workspace (ratatui TUI + SQLite cache), last commit 2026-06-25 (~10
  weeks before this discussion), with an explicit "add-a-workflow" playbook that would make a new
  `PrKind` (e.g. "reply needed") a small addition *if* hub's push/no-daemon decisions were
  reversed. Verified directly via a research agent reading the repo; not independently re-checked
  beyond that report.
- `tools/agents/config/skills/review-prs/fetch_prs.py`: `MY_USERNAME = "ooloth"` and
  `IGNORED_REPOS = ["recursionpharma/build-pipelines"]` are hardcoded; the GraphQL query is
  `is:pr is:open archived:false user:recursionpharma review-requested:ooloth
  -repo:recursionpharma/build-pipelines sort:created-desc`. Confirmed by reading the file directly.
- `gh api user --jq .login` returns `ooloth`, matching the `~/Repos/ooloth/` folder name — a new
  skill can resolve "my username" this way instead of hardcoding it. Confirmed by running the
  command directly.
- `~/Repos` has three owner folders: `ooloth` (8 repos), `recursionpharma` (39 repos), `yazi-rs`
  (1 third-party repo). "Find the repo on disk from a name" needs to filter by the user's own
  GitHub login or by git remote ownership, not assume a single owner folder. Confirmed via a
  research agent's directory listing; not independently re-checked.
- Decided in this discussion: push notifications land in a Slack DM to the user (a Slack MCP
  connector is available); the tracking-doc pattern for this initiative follows
  [ooloth/puzzles](https://github.com/ooloth/puzzles/tree/main/docs)'s `docs/questions/` +
  `docs/decisions/` structure, introduced to this repo for the first time by this file.
