---
number: 002
status: accepted
date: 2026-10-20
---

# 002 — A tool's update prerequisites live in its own `tools/{tool}/preflight.bash`

## Forced by

On 2026-10-20 a `u` run on the work laptop took 1h 12m. `tools/codefresh/update.bash` failed
near the end because the Docker daemon was not running. Its guard checks `have docker`, which
finds the binary but says nothing about the daemon. Expired gcloud application-default
credentials would fail the same way partway through: on the work laptop `uv tool install
--upgrade`, which `tools/harlequin`, `tools/ty`, `tools/visidata` and `tools/neovim` run, installs
through the work Artifact Registry index set in `~/.config/uv/uv.toml` (see `CONTRIBUTING.md`).
Each prerequisite was known before the run started, so each failure could have been reported in
the first seconds.

## Decision

A tool whose update depends on outside state has an optional `tools/{tool}/preflight.bash`. It
checks that state, such as whether the Docker socket answers or whether gcloud can mint a token,
and exits non-zero with the command that fixes it. It applies the same device guard as the
tool's `update.bash` (for example `is_work && have docker`), so it runs only where that update
would. A dependency shared by every update, such as the network, is checked by `u` itself in
`features/update/`, not by any one tool.

The properties this was scored on are: a check tests the same thing its update uses (safety); no
check can change anything (safety); the device knowledge sits next to the dependency it guards
(experience); and adding a tool's prerequisite touches only that tool's folder (experience).

## Rejected

- **One central list in `features/update/`.** A tool that gains a dependency has to be updated
  in a second place, and the list drifts with nothing reporting it. This reverses if
  prerequisites turn out to be shared by most tools, so the list holds a handful of entries.
- **A `require` line inside each `update.bash`, run in a check-only mode first.** In check-only
  mode, every line above `require` actually runs, so a line that writes something would write
  during the check. It needs a CI rule limiting what may sit above `require`. This reverses if
  the duplicated device guard below turns out to drift in practice.
- **Detecting dependencies by scanning each `update.bash` for commands such as `docker`.** Device
  gating happens at runtime (`if ! is_work ...; then exit 0`), so a scan cannot tell whether a
  script runs on this machine. On the Air it would demand Docker for a work-only tool. Wrappers
  also hide commands: `tools/codefresh/bin/codefresh` calls `docker` inside.

## Risk

The device guard is written twice, once in `preflight.bash` and once in `update.bash`. If one
changes and the other does not, the check either blocks a machine that never runs the update or
misses one that does, and the second case brings back the late failure this record exists to
prevent.

## Revisit when

A guard drifts between the two files, or #127 builds an install runner and has to decide whether
`preflight.bash` also covers installs.

## Also update

- [x] `tools/README.md`, `tools/@new/`, `.claude/skills/add-tool/SKILL.md` and `CLAUDE.md`
  describe `preflight.bash`
- [x] `docs/invariants/tools.md` states what `u` depends on: a `preflight.bash` only checks and
  changes nothing
