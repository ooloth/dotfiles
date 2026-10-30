---
updated: 2026-10-29
update_when: the work laptop check below is run, or #204's design resumes
decays: slow
status: open
---

# What command starts the repo's Python?

## Why it matters

[Decision 007](../decisions/007-scripts-that-are-run-are-written-in-python.md) moves scripts that
are run to Python over time, and the approach on #203 keeps every crossing between bash and Python
a process start: a ported step is started from wherever its bash version was. So every caller
needs a way to start one of the repo's Python entry points. The callers are bash runners such as
`u`, zsh aliases such as `symlinks`, `check` and `cc`, the hook in
`tools/claude/config/settings.json`, `tools/rex/config/init.lua` at Rex's boot, the CI workflow,
Amp orbs running `scripts/check.bash` on Debian, and the instruction in
`tools/claude/config/CLAUDE.md` that starts `cc.bash`. Without one stated command, each sub-issue
of the port picks its own, and a start that rewrites `uv.lock`, needs the network, or runs code
from the caller's directory goes unnoticed until it misbehaves.

#204, which creates `pyproject.toml` and `uv.lock`, waits on this answer, because the answer
decides how the project is packaged and whether `uv.lock` can be shared between this repo's
machines. Its design had reached the findings recorded below when it stopped.

## What would settle it

**First, whether the work laptop can download packages from PyPI directly.** A lock shared between
machines records PyPI as each package's source, and the work laptop's `~/.config/uv/uv.toml` points
uv at the work Artifact Registry instead (see `CONTRIBUTING.md`). Run this on the work laptop:

```sh
cat ~/.config/uv/uv.toml
UV_NO_CACHE=1 uv run --no-project --no-config --index https://pypi.org/simple --with six==1.17.0 python -c 'import six; print("pypi reachable")'
```

The first command shows which index the managed config sets and whether it blocks other indexes.
The second downloads one small package straight from PyPI, ignoring that config, with no cache.
`pypi reachable` means the network allows PyPI. A connection, certificate or 403 error means it
does not. The [bootstrap question][boot] asks for the first command too.

**Then, a command that meets every property below**, chosen from the options with the lock option
the answer above leaves standing, tried on #206's link steps before the other categories copy it,
with a check that fails on any start of the repo's Python that does not use it.

- It works from any working directory without changing it, because the project commands act on
  the directory they are run in.
- It starts on this Mac, in CI, in Amp orbs and on the work laptop, including at Rex's boot with
  no network and on a work laptop before gcloud is logged in.
- A `uv.lock` out of step with `pyproject.toml` is caught before it reaches `main`.
- The directory the caller is in cannot change which code runs.
- Adding a tool or a step needs no registration, as adding a `*.bash` step needs none today.
- Tests and `ty` import the same code the command starts.

## Resolves into

A decision record in `../decisions/` naming the command that starts the repo's Python, how
`uv.lock` is shared between machines, and the check that every caller uses the command. If the
lock cannot be shared, decision 008, which commits one `uv.lock`, is superseded too.

## Source

Split on 2026-10-25 from the question that decisions 007 and 008 answered, as "How does unported
bash call the repo's Python?". The full findings of that question are in
[its last version](https://github.com/ooloth/dotfiles/blob/f923e2e55c6ac92cadf63f62b2e9c5829e5cf29e/docs/questions/how-should-this-repos-python-be-set-up-and-bootstrapped.md).
Widened on 2026-10-29 by the approach on #203, which found that every crossing is a process start
and that callers other than bash need the same answer. A decision record choosing
`uv run --locked` was drafted the same day and withdrawn before it was committed, when #204's
design found that `--locked` fails wherever uv is set to a different index.

## Options

How the command starts the code:

- **By file path: `uv run <lock flag> --no-dev --project "$DOTFILES" python -P
  "$DOTFILES/tools/<tool>/<step>.py"`, with the repo root on `sys.path` through the project's
  editable install.** Each step stays in its tool's folder, runners find steps by globbing paths as
  they do today, and tests import the same file as `tools.<tool>.<step>`. A script started by path
  puts its own folder first on `sys.path`, not the caller's, so it is safe even when someone types
  it without `-P`. Its cost is the longest command of the options, and a step must use absolute
  imports. This was the drafted choice.
- **As a module: `... python -P -m tools.<tool>.<step>`.** Callers and tests name the code the same
  way. Without `-P`, `python -m` puts the caller's directory first on `sys.path`, so run inside
  another repo that has its own `tools/` package, it runs that repo's code. It is safe only while
  every caller remembers `-P`.
- **A console script per entry point in `[project.scripts]`.** Short commands, and a console script
  never puts the caller's directory on `sys.path`. Every tool step would need an entry, so adding a
  tool would need registering it, which no step needs today.
- **`"$DOTFILES/.venv/bin/python"` directly.** About 6 ms faster per start. It never checks
  `uv.lock`, and it fails on a machine where the `.venv` has not been created yet.

How `uv.lock` is shared, which the work laptop check decides between:

- **Start with `--frozen`, and catch a stale lock in CI with `uv lock --check`.** A start with no
  runtime dependencies installs nothing, so it works on the work laptop. `check` there installs
  ruff, ty and pytest from the lock's PyPI addresses, which works only if the work laptop can reach
  PyPI.
- **Name PyPI as the project's index in `pyproject.toml`.** A project setting overrides
  `~/.config/uv/uv.toml`, so `--locked` would hold everywhere. `CONTRIBUTING.md` says not to point
  uv at public PyPI on the work laptop, because the managed config blocks that on purpose, so this
  needs the maintainer to decide whether work policy allows it.
- **Commit no `uv.lock`.** Each machine locks against its own index, and `pyproject.toml` pins
  ruff, ty and pytest with `==`. Their dependencies are no longer pinned, and decision 008's
  committed lock is superseded.
- **`--locked` with a shared PyPI lock.** Rejected by the finding below: it fails on any machine
  whose uv is set to a different index.

## Findings

Nothing here is settled until it graduates into a decision record. Every *Measured* finding dated
2026-10-29 was taken in scratch projects with uv 0.13.5 on a personal Apple silicon Mac with no
`~/.config/uv/uv.toml`.

- *Measured (2026-10-29):* with a lock made against PyPI and `UV_DEFAULT_INDEX` set to another
  host, as the work laptop's `uv.toml` sets one, `uv run --locked --offline` treated the lock as
  out of date, tried to resolve against that host, and stopped with an error. It did the same with
  `--no-dev`. `uv run --frozen --offline` started. The lock records each package as
  `source = { registry = "https://pypi.org/simple" }`, so a lock made on the work laptop would
  record the work registry instead, which CI and the personal machines cannot read.
- *Sourced:* `CONTRIBUTING.md` says that on a work laptop uv installs packages through the work
  Artifact Registry index set in `~/.config/uv/uv.toml`, which needs `gcloud auth login
  --update-adc`, and that the managed config blocks falling back to public PyPI on purpose.
- *Measured (2026-10-29):* in a project without packaging (`package = false`), `python -m` run
  from another directory with `--project` could not find the project's modules. In a packaged
  project with `module-root = ""` under `[tool.uv.build-backend]`, the editable install's `.pth`
  file put the project root on `sys.path`. `python -m tools.neovim.link` and
  `python -m features.check.check` then ran from `/tmp`, and `ty` resolved a test's
  `from tools.neovim.link import links` and reported a type error through it. With
  `module-name = "tools"` and `namespace = true`, no `tools/__init__.py` was needed.
- *Measured (2026-10-29):* run from a directory holding its own `tools/neovim/link.py`,
  `uv run --project <repo> python -m tools.neovim.link` ran the caller's file, not the repo's.
  With `python -P -m` it ran the repo's.
- *Measured (2026-10-29):* with a `pyproject.toml` edited after locking, `uv run --locked
  --offline` stopped with an error, while `uv run --frozen` started and failed only when the code
  imported the missing package. With an up-to-date lock and the index it was made against,
  `uv run --locked --offline` started with `UV_NO_CACHE=1`.
- *Measured (2026-10-29):* `uv run --frozen --no-dev` on a project with no runtime dependencies and
  no `.venv` started with `UV_NO_CACHE=1` and an unreachable default index, packaged or not.
- *Measured (2026-10-29):* starting a module with `uv run --frozen` took 19 ms,
  `.venv/bin/python -m` took 13 ms, and a bash process that sources `tools/bash/utils.bash` took
  15.5 ms, each the average of 20 warm runs. A `uv run --no-dev` did not remove dev packages
  already in the `.venv`.
- *Measured (2026-10-29):* in a copy of the repo with a packaged project as above, a dev group of
  `beartype`, `hypothesis`, `pydantic==2.14.1`, `pytest`, `pyyaml`, `ruff==0.16.10` and
  `ty==0.0.85`, and a `pytest.toml` with `--import-mode=importlib`, `testpaths` of `tools`,
  `features` and `scripts`, and `norecursedirs` of `@archive`, `@new`, `.*` and `__pycache__`, one
  `uv run --locked pytest` collected every test file `scripts/checks/tests.bash` runs, with the same
  number of tests in each file. All 505 passed in 183 s, against 193 s for `tests.bash`. ruff and
  `ty --extra-search-path tools/rex` passed from the project.
- *Sourced:* every call from a runner to a step is a process start. `features/update/tools.bash`
  runs each `update.bash` with `bash "$file"`, `features/update/symlinks.bash` runs each
  `link.bash` the same way, and `update_and_symlink` runs a tool's link step with `bash -c`.
- *Sourced:* `symlink()` in `tools/bash/utils.bash` is the only sourced helper that an invariant
  governs (`DOTFILES_CHECK`). The 29 `link.bash` files and `tools/pi/update.bash` are its only
  callers. The helpers most other scripts source (`info`, `debug`, `error`, `warn`, `have`) only
  print output or check that a command exists.
- *Sourced:* Amp orbs have uv preinstalled (`.agents/setup`), and CI installs it with
  `astral-sh/setup-uv`.
- *Sourced:* the tool folders with hyphens or a leading digit in their names (`1password`,
  `carbon-copy-cloner`, `google-chrome`, `terminal-notifier`, `vimium-c`) hold no scripts.
- *Sourced:* of the 25 `update.bash` files under `tools/`, counting the `@new` template, 4 call
  `update_and_symlink` (neovim, node, uv and `@new`).
- *Measured (2026-10-19):* bash tests of `update_and_symlink` need a fake `HOME`, because
  `tools/bash/utils.bash` overwrites `DOTFILES`.

[boot]: how-does-a-fresh-mac-get-uv-and-python-before-the-first-script-needs-them.md
