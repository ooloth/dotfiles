---
number: 009
status: accepted
date: 2026-11-01
---

# 009 — Rex's built-in session restore replaces the saver

## Forced by

[Decision 006](006-a-python-saver-started-from-rex-init-lua-saves-and-restores-rex-sessions.md)
added `tools/rex/saver.py` because the Rex server kept sessions only in memory, and said the saver
is removed when Rex ships its own layout restore. Rex v0.1.0-preview.23 for Mac (2026-10-29
release notes, Rex Beta Discord `#changelog`) says the embedded server now saves sessions and brings
them back when it starts again, "with their tabs, splits, floating panes, names and IDs", each
terminal as a new shell in its old directory, without scrollback. The "Layout restore" request in
`#feedback` was marked completed the same day.

Running both would restore every session twice: the saver rebuilds a saved session unless it finds
an empty one-pane session to build into, and the sessions Rex restores are not empty.

A throwaway `rex server run` server on 2026-11-01 checked the built-in restore. It was stopped with
SIGTERM and then with SIGKILL, and each time it brought back two sessions with their tab labels,
active tab, nested split directions and ratios, pane labels, a floating layer and its bounds, and
every pane's directory, including one changed with `cd` after the pane started. A bare `zsh -f`,
which reports no directory to Rex, also came back in the directory it had moved to, so Rex reads
the process's own directory and needs no shell hook.

## Decision

Rex's own restore is the only thing that rebuilds sessions after a restart. `saver.py`, its tests,
`tools/rex/shell.zsh` (the `cd` hook and the saver warning), the saver step in
`tools/rex/update.bash` and the `start_session_saver` block in `tools/rex/config/init.lua` are
removed. A test in `tools/rex/tests/test_init.py` checks that loading `init.lua` starts no
background program.

## Rejected

- **Keep the saver in the repo but never start it.** The README, the shell warning and four tests
  would describe and check a program that never runs.
- **Keep the saver running to save layout history, without restoring.** It keeps the one thing Rex
  lacks, the last 20 layouts in `history/`. It is rejected because it would still read the Rex CLI
  and server API on every change, and 006 named that as its risk: Rex publishes no compatibility
  policy for either, so an update could break it.

## Risk

Rex keeps one snapshot, so an older layout can no longer be recovered by hand, and #215 (bringing
back a tab or session closed by mistake) loses the saver's `history/` as its starting point. #214
(resuming Claude Code conversations after a restart) and #216 (no extra empty session after a
restart, and the right session in focus) also named the saver as where their change would go. The
saver did #216's part itself, by closing the app's empty session and rebuilding the focused one
inside it, and Rex's own restore may not. The real check is a restart of the app's own server, which
the throwaway server only stands in for. Rex's restore is new and still in beta: an open `#feedback`
bug reports that restoring after a quit brought back only one tab per session.

## Revisit when

A restart brings back fewer sessions, tabs or directories than were open, or brings any session back
twice.

## Also update

- [x] `tools/rex/README.md` — "Sessions after a restart" describes Rex's own restore
- [x] Decision 006 — status line saying 009 supersedes it
- [x] #210 — a comment saying `saver.py` no longer needs moving into the Python project
- [x] #214 — a comment saying the saver is gone, so the conversation resume needs another home
- [x] #215 — a comment adding the open question of where closed tabs and sessions are kept
- [x] #216 — a comment saying what Rex's own restore does with the extra empty session and focus
