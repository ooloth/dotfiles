---
number: 008
status: accepted
date: 2026-10-25
---

# 008 — The repo's Python is one uv project at the repo root

## Forced by

[Decision 007](007-scripts-that-are-run-are-written-in-python.md) moves every script that is run
to Python, and those scripts share helpers today: about 90 files source `tools/bash/utils.bash`.
The 2026-10-19 spike in the
[question this answered](https://github.com/ooloth/dotfiles/blob/f923e2e55c6ac92cadf63f62b2e9c5829e5cf29e/docs/questions/how-should-this-repos-python-be-set-up-and-bootstrapped.md)
ported `update_and_symlink`, which four `update.bash` files call, and needed a shared
`brew_formula` helper to do it. Today the repo has no `pyproject.toml`: ruff and ty run through
`uv run --with` at versions pinned in `scripts/checks/versions.bash`, and each test file is its
own uv script with its own dependencies.

## Decision

One `pyproject.toml` and `uv.lock` at the repo root hold the dependencies and settings for all of
the repo's Python: the package that scripts and tests import, and the dev tools ruff, ty and
pytest that `check` runs over it. The maintainer pointed at `~/Repos/ooloth/agency-1` and
[ooloth/media](https://github.com/ooloth/media) as the setups to follow.

This settles the layout only. How a fresh Mac gets uv and Python before the first script needs
them, and how unported bash calls the Python in the meantime, stay open in the
[bootstrap question][boot] and the [transition question][transition].

## Rejected

- **Single-file uv scripts with inline dependencies.** The global Python standards allow them for
  scripts, and each runs with no project around it. It is rejected because one script cannot
  import another, so helpers shared across tools, such as the spike's `brew_formula`, would be
  copied into every script that uses them. It reverses if the ported scripts turn out to share
  nothing.
- **Not yet.** Each test keeps running as its own uv script until #127 starts. It is rejected
  because every sub-issue of the Python migration needs the shared config first, and the
  migration has started.

## Risk

The project needs uv and a Python before anything in it runs. On a personal Mac uv downloads
Python from `releases.astral.sh`. On a fresh work laptop that is unverified, and if it fails
before gcloud is logged in, setup's first step has to get Python some other way.

## Revisit when

The work-laptop check in the bootstrap question shows that a fresh work laptop cannot get
Python before `u` first runs, or the ported scripts turn out to share no code.

## Also update

- [x] what is still open is split into the two questions named above
- [ ] `CONTRIBUTING.md` describes the project's commands once it exists

[boot]: ../questions/how-does-a-fresh-mac-get-uv-and-python-before-the-first-script-needs-them.md
[transition]: ../questions/how-does-unported-bash-call-the-repos-python.md
