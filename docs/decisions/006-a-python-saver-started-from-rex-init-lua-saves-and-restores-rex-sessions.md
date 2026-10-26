---
number: 006
status: accepted
date: 2026-10-25
---

# 006 — A Python saver started from Rex's `init.lua` saves and restores Rex sessions

## Forced by

The Rex server keeps sessions only in memory, so a server restart or a reboot removes every
session, tab and split. The work laptop reboots daily. The server log at
`~/Library/Application Support/rex/servers/*.log` shows the 2026-10-23 restart, caused by an app
update, leaving none of the earlier sessions. Rex has no restore of its own: the team deferred
"Persist/resurrect sessions" on 2026-10-08 and wrote "we want to encourage use of
Lua/scripting/APIs to do this to fit your use-case" (Rex Beta Discord `#feedback`). On 2026-10-18
mitchellh wrote "Layout restore is planned" in the open "Layout restore" thread, with no date.

## Decision

A Python script, run by `uv`, saves every session's layout and restores it on a new server
instance. `tools/rex/config/init.lua` starts it with `rex.exec.start`. It reads the server through
the `rex` CLI (`rex api call`, `rex events --all --json`), and an OS file lock keeps one copy
running. Python's frozen dataclasses checked by `ty`, Pydantic at the boundary, and `hypothesis`
tests running on the same interpreter as the saver are what decide it over a Lua script inside
Rex.

A spike on a throwaway server on 2026-10-25 showed the API carries everything needed: one
`session.create` call rebuilt two tabs with nested splits, labels and working directories with
no difference, and `rex events --all --json` delivered `pwd_changed` from every session.

## Rejected

- **A Lua script run by `rex do`, inside Rex.** Its strongest case is that a restore depends on
  nothing but Rex. It is rejected because its tests would not run on the code that ships: `rex do`
  reports `Lua 5.1` from Rex's own embedded interpreter, so tests would run on `luajit` or Lua 5.5
  instead, and nothing checks its types. This reverses if `uv` or its cache proves unreliable at
  boot on the work laptop.
- **`cemcatik/rexurrect`, a community Rust tool run by a launchd agent.** Its strongest case is
  about 170 tests against real Rex servers and a maintainer who fixed the Rex 1203 breakage the
  same day. It is rejected because it writes plain-text scrollback and every recorded command to
  disk, which the maintainer does not want on a work laptop. This reverses if it gains a mode that
  writes only layouts and working directories.
- **`blacktop/rexurrect`, a community Go tool run by a launchd agent.** It is rejected because a
  restore it cannot resolve stops every later save, with only a log file to say so
  (`internal/rex/auto.go:100`).
- **Not yet: wait for Rex's own layout restore.** It is rejected because it has no date and the
  reboot happens every day. When it ships, this saver is removed.

## Risk

A restore after a reboot also needs `uv`, a Python interpreter, and the saver's dependencies in
`uv`'s cache. Rex publishes no compatibility policy for its CLI output or server API, so a Rex
update can break the saver. The saver reports both through a warning in Rex panes rather than
failing silently, but the warning is only as good as its check.

## Revisit when

Rex ships its own layout restore, or the saver's warning fires because `uv`, Python or the cache was
unavailable at boot.

## Also update

- [x] `tools/rex/README.md` describes the saver, its warning and how to remove it
