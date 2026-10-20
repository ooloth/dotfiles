---
number: 001
status: accepted
date: 2026-10-20
---

# 001 — Tool tests live in `tools/{tool}/tests/`, and one script finds and runs them all

## Forced by

Each tool test had to be named twice: once in `.github/workflows/test-dotfiles.yml` and once in
`CONTRIBUTING.md`, as `tools/claude/test_update.py` was. A test missing from either list is never
run, with nothing reporting it. A `test_*.py` next to a
tool's scripts was also not part of the tool folder layout in `tools/README.md` or `tools/@new/`.

## Decision

A tool's tests are `tools/{tool}/tests/test_*.py`. `scripts/test-tools.bash` finds them, runs each
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
tests under `tools/agents/config/skills/` run through `test-claude-skills.yml`, but a tool test
nested anywhere else would go unrun.

## Revisit when

`features/` gains tests, so the same convention can cover them, or a tool needs a test file deeper
than `tests/`.

## Also update

- [x] `tools/README.md`, `tools/@new/`, `.claude/skills/add-tool/SKILL.md`, `CLAUDE.md` and
  `docs/invariants/tools.md` describe the `tests/` folder
- [x] `CONTRIBUTING.md` and `.github/workflows/test-dotfiles.yml` call `scripts/test-tools.bash`
