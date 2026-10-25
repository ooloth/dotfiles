---
number: 007
status: accepted
date: 2026-10-25
---

# 007 — Scripts that are run, not sourced, are written in Python

## Forced by

The repo has about 5,700 lines of bash, and the maintainer wants normal programming tooling and a
test suite that does not drive bash through a subprocess. The findings in the
[question this answered](https://github.com/ooloth/dotfiles/blob/f923e2e55c6ac92cadf63f62b2e9c5829e5cf29e/docs/questions/how-should-this-repos-python-be-set-up-and-bootstrapped.md)
measured what that tooling catches. Of four bugs injected into the same code, shellcheck caught
one (a misspelled variable). Ruff and `ty` caught all four, including a misspelled function name
and a call missing an argument, which in bash shifts every later argument into the wrong
parameter. Several 2026 fix commits were bugs a linter or type checker would have caught before
running (`9cbc7fc5`, `73ae9b13`, `cb4a5605`).

## Decision

A script that is run as its own process is written in Python. Shell remains only where a separate
process cannot do the job: the `shell.zsh` files, which change the interactive shell's environment
and working directory, and the first step of setup, which runs before any other language is
installed. Existing bash moves to Python over time and does not have to move at once.

The work-laptop check (whether uv can download Python before gcloud is logged in) does not bear on
this decision. It decides how early in setup Python becomes available, which is part of the
bootstrap question that stays open. Scripts that `u` runs start after setup has finished.

How the Python is laid out is settled by
[decision 008](008-the-repos-python-is-one-uv-project-at-the-repo-root.md). How setup gets
Python onto a fresh machine is open in the [bootstrap question][boot].

## Rejected

- **Stay in bash, with stricter shellcheck.** It costs nothing and changes no bootstrap. It is
  rejected because shellcheck cannot see a misspelled function name or a wrong argument count,
  which is the class of bug the maintainer wants caught before running. It reverses if shellcheck
  or another bash tool starts catching those two.
- **Rust.** Setup would need a Rust toolchain and a compile step before doing anything, and
  `features/setup/setup.zsh` installs Rust only on personal machines. It is rejected because its
  strengths, speed and single binaries, do not help scripts that spend their time waiting on
  `brew`: one `brew list --version` call took 394 ms, against 15 ms to start Python. It reverses
  if the repo gains scripts whose own computation dominates their run time.
- **Not yet.** Waiting keeps every option open, but #127 plans to rewrite setup, and writing it in
  bash first would mean writing it twice. Every new bash script added while waiting adds to the
  later rewrite.

## Risk

For a long time both languages run, and bash calls into Python. About 90 files source
`tools/bash/utils.bash`, which Python cannot source, so how unported bash reaches the Python code
still needs a plan. The guarantees in `../invariants/tools.md`, such as `DOTFILES_CHECK` making
`link.bash` read-only, have to be carried into the Python versions. Ruff's S603, S607 and T201
rules would fail every subprocess call and every progress message, so they will be turned off.

## Revisit when

A Python port of a script produces a bug that ruff and `ty` should have caught and did not, or
the work-laptop check shows that a fresh work laptop cannot get Python at any point before `u`
first runs.

## Also update

- [x] the language question is narrowed to how the Python is set up and bootstrapped
- [x] `../questions/which-bash-version-must-this-repos-scripts-support.md` refers to this record
- [ ] `CLAUDE.md` and `CONTRIBUTING.md` say new scripts that are run are written in Python, once
      the project from decision 008 exists

[boot]: ../questions/how-does-a-fresh-mac-get-uv-and-python-before-the-first-script-needs-them.md
