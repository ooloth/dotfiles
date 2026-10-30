---
number: 001
status: accepted
date: 2026-10-20
amended: 2026-10-20
---

# 001 — Tool tests live in `tools/{tool}/tests/`, and one script finds and runs them all

## Forced by

Each tool test had to be named twice: once in the CI workflow (now `.github/workflows/check.yml`)
and once in `CONTRIBUTING.md`, as `tools/claude/test_update.py` was. A test missing from either
list is never run, with nothing reporting it. A `test_*.py` next to a tool's scripts was also not
part of the tool folder layout in `tools/README.md` or `tools/@new/`.

## Decision

A tool's tests are `tools/{tool}/tests/test_*.py`. `scripts/checks/tests.bash` finds them, runs each
with `uv run` so its inline script dependencies install, and fails if any test fails or none are
found. It also fails on a `test_*.py` placed directly in `tools/{tool}/`, because the runner would
otherwise skip it. CI and `CONTRIBUTING.md` each call the script once. `tools/@new/tests/.gitkeep`
puts the folder in the template.

## Rejected

- **Tests beside the tool's scripts, each listed in CI and `CONTRIBUTING.md` (the previous
  layout).** A test left off either list never runs, and nothing reports the omission.
- **`uv run --with pytest pytest tools/*/tests`.** pytest ignores each file's inline dependency
  header, so `hypothesis`, which `tools/claude/tests/test_update.py` needs, would have to be listed
  by hand in CI. This reverses if the tests move to a shared `pyproject.toml`.
- **A glob loop written into the CI workflow.** It cannot also run from `CONTRIBUTING.md` as the
  same command, so a local run and CI could drift apart.

## Risk

The runner only looks at depth 3 (`tools/{tool}/tests/`) and depth 2 (a misplaced test). A
`test_*.py` deeper in a tool's subtree is not run by it. That is deliberate for skills, whose
tests under `tools/agents/config/skills/` run through pytest in the same script, but a tool test
nested anywhere else would go unrun.

## Revisit when

`features/` gains tests, so the same convention can cover them, or a tool needs a test file deeper
than `tests/`.

## Also update

- [x] `tools/README.md`, `tools/@new/`, `.claude/skills/add-tool/SKILL.md`, `CLAUDE.md` and
  `docs/invariants/tools.md` describe the `tests/` folder
- [x] `scripts/check.bash` and `.github/workflows/check.yml` call `scripts/checks/tests.bash`

## Addendum (2026-10-20) — features

The first feature test, `features/update/tests/test_preflight.py`, arrived the same day, so the
convention now covers `features/{feature}/tests/test_*.py` too. `scripts/checks/tests.bash`
searches both `tools/` and `features/`, and fails on a `test_*.py` placed directly in either kind
of folder.

## Addendum (2026-10-20) — one tests check

The runner moved to `scripts/checks/tests.bash` when decision 005 grouped every check by category.
It now also searches `scripts/*/tests/`, and it runs the `link.bash` check and the skills' pytest
suite as well, so every test runs from one script. `test_symlinks.py` moved to
`features/update/tests/`, beside the feature it tests, and the docs checker's tests moved to
`scripts/checks/tests/test_docs.py`.

## Addendum (2026-10-30) — one pytest run

`scripts/checks/tests.bash` now runs every test in one pytest run, spread across the machine's
cores by pytest-xdist, instead of one `uv run` per file and a separate pytest run for the skills.
Run one file at a time, the suite took 5 to 8 minutes on a work laptop, and most commits waited on
it. In one run it took 88 s, collecting the same tests from each file.

This is the option rejected above as `uv run --with pytest pytest tools/*/tests`. Its reversal
condition, a shared `pyproject.toml`, is the end state of decision 008, and that migration has
started. Until #204 creates the project, the objection to it, that each file's dependencies would
be listed by hand, is met another way: `scripts/checks/test-dependencies.py` reads each test file's
inline script header, and `tests.bash` installs every package it prints. The header stays the one
place a test file's dependencies are written, so each file still runs on its own with
`uv run <file>`. A package missing from every header fails the run with an `ImportError`, and two
headers that pin different versions of one package fail when uv resolves them.

pytest searches `tools/`, `features/` and `scripts/` at any depth, skipping `@archive/` and
`@new/`, so the depth limits in the risk above no longer leave a test unrun. A `test_*.py` placed
directly in a tool or feature folder still fails the check, because it breaks the layout this
record sets.
