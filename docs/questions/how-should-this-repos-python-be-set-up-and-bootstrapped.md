---
updated: 2026-10-25
update_when: the work laptop check below is run, #127 starts, or a script is rewritten in Python
decays: slow
status: open
---

# How should this repo's Python be set up and bootstrapped?

## Why it matters

[Decision 007](../decisions/007-scripts-that-are-run-are-written-in-python.md) settled that
scripts that are run, not sourced, are written in Python, and
[decision 008](../decisions/008-the-repos-python-is-one-uv-project-at-the-repo-root.md) settled
that it is one uv project at the repo root. What is left open is how a fresh Mac gets uv and
Python before the first script needs them, and how unported bash calls the Python while both
languages run.

#127 plans to replace `features/setup/setup.zsh` and cannot start until the first of these is
answered, because it decides how much of setup's first step has to be bash.

## What would settle it

Two things, and #127 waits for both.

1. **Whether a fresh work laptop can run Python before gcloud is set up.** The project needs uv to
   download Python, and on a work laptop the managed uv config may route that download through
   Artifact Registry, which needs Application Default Credentials first. Run this on the work
   laptop:

   ```sh
   cat ~/.config/uv/uv.toml
   UV_PYTHON_INSTALL_DIR=$(mktemp -d) uv python install 3.10 -v
   ```

   The first command shows whether the managed config sets `python-downloads`, a
   `python-install-mirror`, or `python-preference`. The second downloads a Python into a scratch
   directory without touching the installed ones. Look for which URL it downloads from and
   whether it fails. A laptop that already has gcloud logged in can hide an Artifact Registry
   dependency, so to see what a fresh laptop sees, run the second command again after
   `gcloud auth application-default revoke`, then log back in with
   `gcloud auth application-default login`.

   A failure tells you which of these is in the way: the network blocks the download host, a
   proxy re-signs HTTPS with a company certificate that uv does not trust without
   `--system-certs`, or the managed config disables or redirects Python downloads.

2. **A plan for the time when both languages run.** About 90 files source
   `tools/bash/utils.bash`, and Python cannot source bash. Unported bash needs a stated way to
   reach the Python code, such as calling the package's command-line entry point.

## Resolves into

A decision record in `../decisions/` on how setup gets uv and Python onto a fresh Mac, and one on
how bash calls the Python during the port. #127 follows the first.

## Source

Raised on 2026-10-19 by the maintainer, asking whether the repo should move to Python or Rust so
that it can have a good test suite and normal programming tooling. The maintainer pointed at
`~/Repos/ooloth/agency-1` as the Python setup they enjoy: a `pyproject.toml` with `uv.lock`, a
package its tests import, ruff with `select = ["ALL"]`, `ty` over the whole program, pytest, and
prek hooks that ban `noqa` comments. Narrowed on 2026-10-25, when the maintainer settled the
language as Python (decision 007) and pointed at
[ooloth/media](https://github.com/ooloth/media) as an example of repo-level uv config shared by
all of a repo's Python tooling.

## Options

None written yet for either part. The layout options this file used to hold are recorded in
decision 008.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Sourced:* fix commits from 2026 that a type checker or linter would have caught before running
  include `9cbc7fc5` (broken variable references in mise), `73ae9b13` (wrong variable name in
  node) and `cb4a5605` (broken `source` lines in `tools/macos/install.bash`). `73323b90` (wrong
  symlink script paths) is a path on disk, which no checker in either language catches.
- *Measured (2026-10-19):* a spike ported `update_and_symlink` from
  `features/update/utils.bash` to a Python package with agency-1's `pyproject.toml`, `ruff.toml`,
  `ty` and pytest. The bash is 62 lines across `features/update/utils.bash` and
  `features/utils.bash`. The Python is 105 lines, including the three outcome types, a
  `brew_formula` helper and a `main`.
- *Measured (2026-10-19):* the same three behaviour tests (install a missing tool, upgrade and
  link, link when already latest) ran against both versions using stub `brew` and `nvim` scripts
  on `PATH`. All 6 passed, and removing the link step from each version failed the 4 tests that
  cover it. The Python tests compare returned values such as `Upgraded("0.11.0", "0.12.0")`. The
  bash tests match text in stderr and need a fake `HOME`, because `tools/bash/utils.bash`
  overwrites `DOTFILES` (which `tools/agents/config/standards/bash.md` says a script should not
  rely on).
- *Measured (2026-10-19):* four bugs were injected into each version and checked with the repo's
  `.shellcheckrc` against ruff and `ty`:
  - A misspelled variable: shellcheck caught it (SC2154), and ruff caught it (F821).
  - A misspelled function name: shellcheck missed it, and ruff caught it (F821).
  - A `source` or import of a missing file: shellcheck missed it, and `ty` caught it
    (`unresolved-import`).
  - A call missing one argument: shellcheck missed it, and `ty` caught it (`missing-argument`).
    In bash, every later argument shifts into the wrong parameter.
- *Measured (2026-10-19):* with SC1091 turned back on (`shellcheck --norc -x` from the repo
  root), shellcheck does catch a `source` of a missing file. Across the repo it reports 5 such
  lines today, all in `tools/@archive/television/`, and every one points at a file that does not
  exist.
- *Measured (2026-10-19):* when a sourced file was missing in the spike's copy of the repo, the
  bash printed "No such file or directory" and carried on, exiting 0.
- *Measured (2026-10-19):* a misspelled function in the bash failed only the one test whose path
  reached it, and the other two passed. Tests find these bugs only on the paths they run, and `ty`
  finds them on every path.
- *Measured (2026-10-19):* with agency-1's ruff config, every `subprocess` call fails S603 and
  every call to `brew` by name fails S607, and the progress output fails T201 (`print`). agency-1
  allows `noqa` only for S603. A Python version of this repo would ignore S603, S607 and T201 in
  `ruff.toml`, since running commands by name and printing progress are its whole job.
- *Measured (2026-10-19), on an M-series Mac with stub `brew`:* one up-to-date update took 34 ms
  in bash and 47 ms in Python, 49 ms through `uv run --frozen`. Starting an empty Python took
  15 ms. One real `brew list --version neovim` took 394 ms, and an update makes at least two such
  calls plus `brew upgrade`, so the language's own time is under 5% of a real run.
- *Measured (2026-10-19):* uv 0.13.2 downloads Python from `releases.astral.sh`, not from PyPI or
  the package index set in `~/.config/uv/uv.toml`. This was measured on a personal machine with no
  `uv.toml`.
- *Unverified:* whether a fresh work laptop can download Python with uv before gcloud is logged
  in. The check under **What would settle it** answers it.
- *Reasoned:* the global Python standards call for Pydantic at boundaries. A setup that has to run
  before gcloud is logged in cannot install third-party packages on a work laptop, so the runtime
  code would be limited to the standard library, with ruff, `ty` and pytest only in the dev group.
  Whether `uv run --no-dev` on a project with no runtime dependencies reaches the package index at
  all is *Unverified*.
- *Sourced:* of the 25 `update.bash` files under `tools/`, counting the `@new` template, 4 call
  `update_and_symlink` (neovim, node, uv and `@new`). The other 21 run their own commands. The
  archived `tools/@archive/television/update.bash` calls it too.
