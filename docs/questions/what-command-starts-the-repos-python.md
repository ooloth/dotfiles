---
updated: 2026-11-04
update_when: a command is tried on #206's link steps, or #204's design resumes
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
`tools/claude/config/settings.json`, the CI workflow,
Amp orbs running `scripts/check.bash` on Debian, and the instruction in
`tools/claude/config/CLAUDE.md` that starts `cc.bash`. Without one stated command, each sub-issue
of the port picks its own, and a start that rewrites `uv.lock`, needs the network, or runs code
from the caller's directory goes unnoticed until it misbehaves.

#204, which creates `pyproject.toml` and `uv.lock`, waits on this answer, because the answer
decides how the project is packaged and how `uv.lock` is shared between this repo's machines. Its
design had reached the findings recorded below when it stopped.

## What would settle it

**A command that meets every property below**, chosen from the options, tried on #206's link steps
before the other categories copy it, with a check that fails on any start of the repo's Python that
does not use it.

- It works from any working directory without changing it, because the project commands act on
  the directory they are run in.
- It starts on this Mac, in CI, in Amp orbs and on the work laptop, including on a work laptop
  before gcloud is logged in.
- A `uv.lock` out of step with `pyproject.toml` is caught before it reaches `main`.
- Neither the directory the caller is in nor the caller's `PYTHONPATH` can change which code runs.
- Adding a tool or a step needs no registration, as adding a `*.bash` step needs none today.
- Tests and `ty` import the same code the command starts.
- Every package the project depends on is public, because the permission to use PyPI on the work
  laptop covers only public packages (see Findings). A lock records PyPI as the source of an
  internal name resolved from PyPI too, so no check of `uv.lock` can hold this, and whoever adds a
  dependency confirms it.

## Resolves into

A decision record in `../decisions/` naming the command that starts the repo's Python, how
`uv.lock` is shared between machines, and the check that every caller uses the command. If the
chosen option commits no lock, decision 008, which commits one `uv.lock`, is superseded too.

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

- **By file path: `uv run <lock flag> --no-dev --project "$DOTFILES" python -I
  "$DOTFILES/tools/<tool>/<step>.py"`, with the repo root on `sys.path` through the project's
  editable install.** Each step stays in its tool's folder, runners find steps by globbing paths as
  they do today, and tests import the same file as `tools.<tool>.<step>`. A script started by path
  puts its own folder first on `sys.path`, not the caller's directory, but `PYTHONPATH` still comes
  before the repo root, so it needs `-I` as much as the module form does (see Findings). Its cost
  is the longest command of the options, and a step must use absolute imports.
- **As a module: `... python -I -m tools.<tool>.<step>`.** Callers and tests name the code the same
  way. Without `-I` or `-P`, `python -m` puts the caller's directory first on `sys.path`, so run
  inside another repo that has its own `tools/` package, it runs that repo's code.
- **A console script per entry point in `[project.scripts]`.** Short commands, and a console script
  never puts the caller's directory on `sys.path`. Every tool step would need an entry, so adding a
  tool would need registering it, which no step needs today.
- **`"$DOTFILES/.venv/bin/python"` directly.** About 6 ms faster per start. It never checks
  `uv.lock`, and it fails on a machine where the `.venv` has not been created yet.

How `uv.lock` is shared. Both options that share a lock download from PyPI on the work laptop,
because `uv.lock` records each file's `files.pythonhosted.org` URL and an install fetches that URL
whichever index the machine's config names. Only committing no lock keeps the work laptop on its
managed index. Under either shared-lock option, an internal package added later would resolve its
name from public PyPI, which is why the maintainer's permission covers only public packages (see
Findings).

- **Start with `--frozen`, and catch a stale lock in CI with `uv lock --check`.** A start with no
  runtime dependencies installs nothing. `check` on the work laptop installs ruff, ty and pytest
  from the lock's PyPI URLs, as the measured `six` install did (see Findings); ruff, ty and pytest
  themselves have not been installed this way there. The managed index stays in force on the work
  laptop for every command but `--frozen`, so every other lock command there needs `--no-config`.
  Without it, `uv lock` or `uv add` records the managed index in `uv.lock`, a URL CI cannot read
  and a private value this public repo cannot hold, and `uv lock --check` fails as `--locked` does
  (see Findings).
- **Name PyPI as the project's index in `pyproject.toml`.** A project setting outranks the work
  laptop's user-level `~/.config/uv/uv.toml`, so `--locked` holds everywhere and a stale lock stops
  the start on any machine, with no `--no-config` needed. It stops holding if the work laptop's
  managed config moves to a `UV_*` environment variable, which outranks the project (see Findings).
- **Commit no `uv.lock`.** Each machine locks against its own index, and `pyproject.toml` pins
  ruff, ty and pytest with `==`. Their dependencies are no longer pinned, and decision 008's
  committed lock is superseded. On the work laptop, locking goes through the managed index, so it
  needs gcloud logged in, and setup before login is limited to the standard library (see the
  [bootstrap question][boot]).
- **`--locked` with a shared PyPI lock and no project index.** Rejected by the findings below: it
  fails on any machine whose uv is set to a different index.

Whichever option wins, the project can also refuse packages uploaded in the last seven days, so a
compromised release is likely pulled before a lock picks it up. Set as `exclude-newer = "7 days"`
under `[tool.uv]` in `pyproject.toml`, it reaches every machine. Set in one machine's `uv.toml`
instead, it breaks `--locked` everywhere else (see Findings).

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
- *Measured (2026-10-29):* with PyPI named as the project's default index in `[[tool.uv.index]]`
  and a user-level `uv.toml` (through `XDG_CONFIG_HOME`) setting an unreachable default index,
  `uv run --locked --no-dev --offline` started, because project settings outrank user settings.
  With the same index set through `UV_DEFAULT_INDEX` or `UV_CONFIG_FILE` instead, the project's
  setting lost and `--locked` failed. So naming PyPI in the project holds against the work laptop
  only if its managed config is a user-level or system-level file, and not a `UV_*` environment
  variable. The work laptop's is the user-level file (see the 2026-11-02 findings).
- *Measured (2026-11-02):* with uv 0.13.6, in a scratch project with a lock made against PyPI, a
  system-level `uv.toml` found through `XDG_CONFIG_DIRS` and naming an unreachable default index
  made `uv run --locked` fail with a DNS error. With PyPI named as the default in
  `[[tool.uv.index]]`, the same system-level file lost and `uv run --locked` started.
- *Measured (2026-10-29):* a lock made with `exclude-newer = "7 days"` in a user-level `uv.toml`
  recorded `exclude-newer-span = "P7D"` under `[options]` in `uv.lock`. Without that setting,
  `uv run --locked` then failed with `To update the lockfile, run uv lock`. With it, `--locked`
  started.
- *Sourced:* `CONTRIBUTING.md` says that on a work laptop uv installs packages through the work
  Artifact Registry index set in `~/.config/uv/uv.toml`, which needs `gcloud auth login
  --update-adc`, and that the managed config names that index as the only default.
- *Sourced (2026-11-02):* the work laptop's managed config is only the user-level
  `~/.config/uv/uv.toml`. It names one index, marked `default = true` with `authenticate =
  "always"`, and its comments say the single index guards against name-collision attacks between
  internal and public package names. `env | grep '^UV_'` printed nothing, and neither
  `/etc/uv/uv.toml` nor `/Library/Application Support/uv/uv.toml` exists. `XDG_CONFIG_DIRS` is
  unset and `/etc/xdg/uv/uv.toml` does not exist, so uv finds no system-level config there either.
- *Sourced (2026-11-02), the maintainer:* this repo's packages, runtime and dev alike, may be
  downloaded from PyPI on the work laptop, because the repo depends only on public packages and so
  has no internal name for a public package to collide with. The permission holds only while every
  dependency is a public package. With PyPI named as the project's index, an internal package
  added later would resolve its name from public PyPI, which is the collision the managed config's
  single index guards against.
- *Measured (2026-11-02):* on the work laptop with uv 0.13.6, `UV_NO_CACHE=1 uv run --no-project
  --no-config --index https://pypi.org/simple --with six==1.17.0` downloaded and imported `six`.
  The network allows PyPI.
- *Measured (2026-11-02):* on the work laptop with uv 0.13.6, its managed config active and gcloud
  logged in, in scratch projects depending on `six==1.17.0`:
  - With a lock made against PyPI using `--no-config`, `UV_NO_CACHE=1 uv run --frozen` fetched the
    wheel from the lock's `files.pythonhosted.org` URL and started, and its `-v` log named no
    `pkg.dev` host. `uv run --locked` on the same lock stopped with `The lockfile at uv.lock needs
    to be updated`, and `uv lock --check` exited 1 with `To update the lockfile, run uv lock`. With
    `--no-config`, `uv lock --check` passed.
  - With no project index, a plain `UV_NO_CACHE=1 uv lock` recorded `six` from a `pkg.dev`
    registry and no `files.pythonhosted.org` URL.
  - With PyPI named as the default index in `[[tool.uv.index]]`, `uv lock` run with the managed
    config active recorded `source = { registry = "https://pypi.org/simple" }`, and
    `UV_NO_CACHE=1 uv run --locked` fetched the wheel from `files.pythonhosted.org` and started.
    No request went to the managed index.
- *Measured (2026-11-02):* on the work laptop with uv 0.13.6, its managed config active,
  `UV_NO_CACHE=1`, and gcloud's credentials hidden from uv (`CLOUDSDK_CONFIG` set to an empty
  directory and `GOOGLE_APPLICATION_CREDENTIALS` to a missing file), `uv run --no-project --with
  six==1.17.0` failed with `Incomplete credentials`, as a laptop before gcloud login does. In the
  same environment both shared-lock options installed `six`: `uv run --frozen` on a lock made
  against PyPI, and `uv lock` then `uv run --locked` with PyPI named in `[[tool.uv.index]]`. None
  of their `-v` logs, which name each URL fetched, named a `pkg.dev` host.
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
- *Measured (2026-10-29):* `-P` does not drop a caller's `PYTHONPATH`. From a directory holding
  its own `tools/lib/x.py`, with `PYTHONPATH` set to that directory, a step started by path with
  `python -P` imported the caller's `tools.lib.x`, not the repo's. With
  `python -I`, which also ignores `PYTHONPATH` and the user site, it imported the repo's, and the
  editable install still put the repo root on `sys.path`.
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
- *Measured (2026-10-30):* on the work laptop, with no project, one `uv run --with` pytest run with
  pytest-xdist (`-n auto --dist worksteal`, 14 cores) over `tools`, `features` and `scripts`
  collected the same number of tests from each of the 16 `tests/test_*.py` files as unittest did,
  and all 200 skill tests. It took 132 s at load average 9.7, against about 500 s for one `uv run`
  per file. Its floor is the slowest single test, because xdist does not split one: Hypothesis
  tests that run a subprocess per example took 47 to 115 s each. `scripts/checks/tests.bash` now
  runs this way until the project exists (decision 001's addendum of 2026-10-30).
- *Sourced:* every call from a runner to a step is a process start. `features/update/tools.bash`
  runs each `update.bash` with `bash "$file"`, `features/update/symlinks.bash` runs each
  `link.bash` the same way, and `update_and_symlink` runs a tool's link step through
  `run_link_step`, which runs it with `bash`.
- *Sourced:* the sourced helpers that an invariant governs are all in `tools/bash/utils.bash`:
  `symlink()` (`DOTFILES_CHECK`), the way it sets `DOTFILES` from its own location and
  `DOTFILES_INSTALL` as the install, `require_install_checkout`, which `symlink()` and both
  broken-link sweeps call first, and `run_link_step`, which update and install scripts reach their
  link step through (`docs/invariants/tools.md`). Of the 28 `link.bash` files outside `@new` and
  `@archive`, 27 call `symlink()` (`tools/gemini/link.bash` links nothing), and nothing else calls
  it. The helpers most other scripts source (`info`,
  `debug`, `error`, `warn`, `have`) only print output or check that a command exists.
- *Sourced:* Amp orbs have uv preinstalled (`.agents/setup`), and CI installs it with
  `astral-sh/setup-uv`.
- *Sourced:* the tool folders with hyphens or a leading digit in their names (`1password`,
  `carbon-copy-cloner`, `google-chrome`, `terminal-notifier`, `vimium-c`) hold no scripts.
- *Sourced:* of the 27 `update.bash` files under `tools/`, counting the `@new` template, 4 call
  `update_and_symlink` (neovim, node, uv and `@new`).
- *Sourced:* run from a copy, `update_and_symlink` skips its link step (`run_link_step` in
  `tools/bash/utils.bash`), so a bash test of it needs a fake `HOME` only when it checks the
  links.

[boot]: how-does-a-fresh-mac-get-uv-and-python-before-the-first-script-needs-them.md
