---
number: 005
status: accepted
date: 2026-10-20
---

# 005 — Checks are grouped by category in `scripts/checks/`, and run fastest first

## Forced by

On 2026-10-20 `CONTRIBUTING.md` listed nine commands for checking a change, and CI split them
across four workflows (`test-dotfiles.yml`, `check-python.yml`, `check-docs.yml` and
`test-claude-skills.yml`). `scripts/` held six files under three naming styles:
`check-*.bash`, `check-*.py`, `test_*.py` and `test-*.bash`. One check, `check-python.bash`, was
grouped by language, and one test, `test_symlinks.py`, tested a feature that lives in
`features/update/`. The `check` alias in `features/check/check.bash` had no case for this repo.

## Decision

Each kind of check has one script in `scripts/checks/`, named for the category, not the
language: `formatting.bash`, `docs.py`, `types.bash`, `linting.bash` and `tests.bash`. A tool
for a new language joins the matching script. `versions.bash` pins the tool versions those
scripts share, and `link-scripts.bash` is the `link.bash` check that `tests.bash` runs.

`scripts/check.bash` runs the five in order of how long they take on a warm machine, and stops at
the first that fails. Measured on 2026-10-20: formatting 0.1 s, docs 0.1 s, types 0.3 s, linting
2.3 s with shellcheck running eight files at a time (13.7 s one at a time), and tests about
110 s. `check` from the repo root runs it. `.github/workflows/check.yml` runs the same five
scripts as five steps of one job, in the same order, on every push and pull request.

Every test sits in a `tests/` folder beside the code it tests (decision 001), including the docs
checker's own tests in `scripts/checks/tests/`.

## Rejected

- **CI runs only `scripts/check.bash`, in one step.** It meets every property, but a failure
  shows up as one red "Check" step, and the maintainer wants the failing category visible as its
  own step. This reverses if the steps' setup cost grows enough that one step is much faster.
- **Keep the path-filtered workflows, each calling its category script.** A check added to
  `check.bash` but not to a workflow would never run in CI, with nothing reporting it. This
  reverses if CI time per push becomes a cost the maintainer notices.
- **Group checks by language, as `check-python.bash` did.** Formatting and linting for shell or
  Markdown would each need another file, and the categories CI shows would differ per language.

## Risk

Every push runs every check, about 2 minutes on a warm machine and more in CI, including the
skills' tests when no skill changed. The order is measured on this laptop, so CI's order may not
be strictly fastest first.

## Revisit when

A category's run time changes enough to move it past another, or CI time per push starts to
matter.

## Also update

- [x] `CONTRIBUTING.md` lists `check` and the five category scripts
- [x] `features/check/check.bash` has a `dotfiles` case
- [x] decision 001 notes that its runner moved to `scripts/checks/tests.bash`
