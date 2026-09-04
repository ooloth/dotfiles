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

The diagnosed failure mode: forgetting hub exists for a week, then falling back to manual,
slower, laggier ways of noticing the work queue. Fixing that is now understood to span all of
hub's "needs my attention" domains, not just PRs — the PR-queue question is the concrete case
driving the design, but the answer should generalize.

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

**A. Extend `hub`.** Reopened — no longer rejected. `hub`'s `docs/decisions/009-no-scheduled-runs.md`
and its TUI-refresh decision reject scheduled/unattended runs and a daemon on the premise that
push is undesirable; the user is now willing to override those ADRs if a background daemon
delivers real capability, since off-hours notification reach turned out to be unwanted anyway (see
Findings). New capabilities requested alongside reviving hub: (1) a background daemon that fetches
and detects while the laptop is on, independent of whether any TUI is open; (2) the ability to
open multiple concurrent TUI view instances from any terminal, not confined to a single "hub"
tmux session — unclear yet whether today's binary already supports this (a convention of one
launch script vs. a real single-instance/single-writer constraint needs checking) or requires a
client/server split (daemon owns state; TUI instances become thin attachable clients — a bigger
structural change than ADR 008 anticipated); (3) a possible on/off toggle to pause
watching/notifications (e.g. during focus time) — scope (global vs. per-signal-type) undecided.
Its GraphQL query (`clients/src/github/prs/fetch.rs`) already pulls `reviewThreads` (with
`isResolved`) and comments per PR — reusable for reply detection regardless of how the daemon
question resolves.

**B. A cloud Routine for detection, decoupled from local presence-gated notification.**
Ruled out, not just downgraded — the user does not want off-hours notification reach for this use
case, and has since confirmed there's also no value in *detecting* during periods they don't care
about (see Findings and "Decided, deferred, or ruled out"). A cloud Routine's only advantage
(working while the laptop is closed/asleep) has no remaining use once both delivery and detection
are wanted local-only.

**E. A menu-bar status surface (xbar/SwiftBar plugin, or a native menu-bar app), reusing the same
headless digest binary as options A/D.** Not previously considered; raised in response to "what
else is viable." xbar/SwiftBar runs any script on an interval and renders its stdout as a menu-bar
item — an always-visible ambient indicator (item count, oldest wait time) rather than a transient
notification that can be missed, with a dropdown showing the digest. Complementary to, not
exclusive with, a one-shot OS notification — both could be driven by the same underlying digest
binary once it exists.

**C. `/loop` for periodic local checking.** Reopened, partially — its session-scoped,
close-when-the-laptop-closes behavior was originally treated as a limitation; the user has since
said off-hours notification reach is actually unwanted for this use case, which makes that
behavior correct rather than a defect. The remaining weakness: it requires manually starting
`/loop` each time you sit down, which risks the same "forgot it exists" failure mode as hub. Its
one clear advantage over a bare local daemon: it's already a live Claude session, so LLM reasoning
(classification, investigation) is available at every wake with no extra invocation needed.

**D. A `launchd` LaunchAgent as a local, login-scoped background process, independent of hub.**
Parked, not rejected — would satisfy the presence constraint (runs only while logged in) with no
tab to remember to keep open, and no existing ADRs to reconcile. The user's response leaned toward
reviving `hub` as the background daemon instead of building a new parallel mechanism, but this
remains the fallback if the hub daemon/multi-attach rework turns out to be too costly.

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
- The tracking-doc pattern for this initiative follows
  [ooloth/puzzles](https://github.com/ooloth/puzzles/tree/main/docs)'s `docs/questions/` +
  `docs/decisions/` structure, introduced to this repo for the first time by this file.
- Off-hours notification reach is explicitly unwanted for this use case: the user would treat any
  notification landing while away from a device as PagerDuty-like, which is not the intent for PR
  review. Off-hours *execution* (a routine simply running on a holiday) is acceptable; off-hours
  *delivery* is not. This inverts the earlier framing that favored cloud Routines and disfavored
  `/loop`/hub for not reaching the user while away.
- Slack MCP connector (`mcp__claude_ai_Slack__*`) is installed but not authenticated in this
  session — only `authenticate`/`complete_authentication` tools are exposed, no send-message tool.
  Verifying it (and proving DM-only targeting, to rule out ever posting to a public/wrong channel)
  requires the user to run `/mcp` and authorize first. Confirmed by attempting `authenticate`
  directly, 2026-09-04.

## Notification UX preferences decided so far

- Aggregate digest only ("N items need attention"), not one alert per item. Repeating an
  unchanged item across digests is intentional, not a bug to dedup away — the message reports
  current queue state, not novelty. Chosen over per-item alerting specifically because per-item
  alerts would need real dedup, risking silently dropping a forgotten-but-still-pending item,
  where the digest shape needs no dedup at all.
- Ordering: oldest-first as the starting criterion. The ideal is smarter prioritization later, but
  oldest-first is the baseline to ship first.
- Snooze/dismiss (mark an item seen and deliberately deferred, hide it from the digest for a
  while): not building this now, but the design should keep the door open to adding it without a
  rearchitecture.
- Delivery channel: local macOS notification first. Slack is tracked as a possible later
  enhancement if a concrete UX benefit shows up (e.g. multi-device visibility) — not building it
  now, and the design should not architecturally foreclose adding it later.

## Potential capabilities a durable store would unlock (not committed to building yet)

- Caching per-item LLM investigation results, so the expensive "proactively research and draft a
  recommendation" step isn't redone every tick for an item whose underlying GitHub state hasn't
  changed.
- Snooze/dismiss state (see above) — GitHub has no concept of "I've seen this and am deliberately
  deferring it."
- Cross-item history/audit — e.g. how long something actually sat before it was acted on, for
  reviewing whether the system is working.
- Per-item priority overrides, if a future smart-prioritization scheme needs a place to record
  manual corrections.
- Wait-time ranking for the digest itself does *not* need a store — GitHub's own timestamps
  (review-requested-at, comment-created-at) are sufficient for oldest-first ordering without the
  user maintaining separate state.

## Open sub-questions

- Resolved by reading the code: `hub-tui` has no single-instance lock (no lockfile/PID/port-binding
  found anywhere in `ui/tui/src/`), and `~/.hub/hub.db` is opened in SQLite WAL mode
  (`store/src/status_cache.rs:19-31,71-76`), a tested, supported mode for concurrent
  readers/writers (`store/src/status_cache.rs:238-270` has a test confirming a second writer
  blocks rather than errors). Multiple `hub-tui` instances already work today. Each instance runs
  its own independent 30-minute refresh timer (`ui/tui/src/main.rs:35`,
  `REFRESH_INTERVAL_SECS = 30 * 60`) rather than there being one shared fetcher process — but each
  tick checks the shared cache's freshness before calling GitHub/Linear APIs
  (`ui/tui/src/main.rs:276-293`), so redundant live fetches are partially, not fully, suppressed
  when instances' timers happen to overlap within the same freshness window. Matches the user's
  understanding: acceptable as-is, not elegant, not worth solving now.
- Resolved by reading the code: no client/server split needed. `workflows` (the crate holding
  `workflows::status::run()`, the fetch/detect/sort logic) has zero dependency on `ui/tui` or
  ratatui (`workflows/Cargo.toml` depends only on `anyhow`, `chrono`, `clients`, `domain`,
  `secrecy`, `serde`, `serde_json`, `store`, `tempfile`, `tokio`, `uuid`) — confirmed directly.
  `items.sort_by_key(...)` already runs inside `run()` (`workflows/src/status.rs:215`, confirmed
  directly), so a result is already sorted by urgency/age before any caller sees it. A new headless
  binary can depend on `workflows` directly, call `run()`, print/notify the top-N, and exit — it's
  just another reader/writer of the same shared WAL-mode SQLite DB, the same pattern that already
  lets multiple `hub-tui` instances coexist. `ui/cli` (the existing stub binary, meant for exactly
  this kind of extension) is genuinely empty today — 10 lines, doesn't depend on `workflows` at
  all (confirmed directly) — so this is new code, not a small tweak to something half-built.
  Remaining real cost: there's no existing `Display`/summary formatter on `StatusItem` reusable
  outside the TUI (the only per-variant formatting today is ~770 lines across
  `ui/tui/src/display/{format,pipeline,types}.rs`, all `pub(crate)` to `ui/tui` and built around
  TUI rendering types) — a digest formatter needs its own match arm per variant, roughly 40-60
  lines to cover PR/Issue/CI/Linear (skipping the private Loki/GCP variants). No existing
  notification dependency in the repo (checked all `Cargo.toml`s and source for `notify-rust`,
  `mac-notification-sys`, `osascript`, `NSUserNotification` — none found); shelling out to
  `osascript -e 'display notification ...'` via `std::process::Command` needs zero new
  dependencies. A new binary crate needs adding to the workspace's `Cargo.toml` `members` list and
  (if it touches the `private` feature) a stub directory the way CI already expects for the other
  four crates — otherwise it rides the existing single CI job (`fmt`, `clippy`, `nextest`,
  `audit`, `deny`) automatically.

## Decided, deferred, or ruled out

- On/off toggle for hub's watching/notifications: not solving for this now — minor relative to the
  main ask. Keep the design from foreclosing it later (e.g. don't hardcode "always on" in a way
  that can't add a pause switch without a rewrite).
- Off-machine detection (e.g. a cloud Routine running as a backstop while the laptop is asleep, so
  the first digest after waking is already caught up): ruled out. No value in detecting during
  periods the user doesn't care about; catching up once logged back in is sufficient.
