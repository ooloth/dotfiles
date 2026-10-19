---
updated: 2026-10-19
update_when: a script needs to run against a copy of the repo, or a check needs a DOTFILES of its own
decays: slow
status: open
---

# Should `tools/bash/utils.bash` respect a `DOTFILES` the caller set?

## Why it matters

Line 4 of `tools/bash/utils.bash` sets `DOTFILES` to `${HOME}/Repos/ooloth/dotfiles` every time it
is sourced, whatever the caller set. So no script that sources it can be pointed at a copy of the
repo, a worktree, or a test fixture: it silently reads and writes the main checkout instead. The
comment above the line says it is there "in case this file is sourced before shell variables have
been symlinked", which reads like a fallback, but it overrides. Changing it is not one line either,
because the symlink tests are built around the override, and a worktree's path reaching `u` could
link `$HOME` configs into a directory that is later deleted.

## What would settle it

A list of every caller that runs with a `DOTFILES` other than the main checkout, or would want to,
and for each one the result under each option below. That covers CI, `scripts/test_symlinks.py`,
`scripts/check-link-scripts.bash`, the check #193 plans, and running a script from a scratch copy.
Also a decision on whether `u` run from a worktree should ever link into that worktree.

## Resolves into

A decision record in `../decisions/` on how `tools/bash/utils.bash` sets `DOTFILES`, and a comment
on line 3 that says what the line does.

## Source

Raised on 2026-10-19 while adding `tools/terminal-notifier/`. Running
`tools/homebrew/generate-brewfile.bash` with `DOTFILES` pointed at a scratch copy wrote the main
checkout's `tools/homebrew/Brewfile.generated` instead. The maintainer agreed to record the
question rather than change the line inside that work.

## Options

- **Keep the override and fix the comment.** Every script always acts on the main checkout, so a
  stray `DOTFILES` can never aim `u` at the wrong directory. The cost is that nothing can run
  against a copy without a fake `HOME`, and every new check has to build one.
- **Respect a caller's value:** `export DOTFILES="${DOTFILES:-${HOME}/Repos/ooloth/dotfiles}"`.
  Copies and fixtures work by setting one variable. The cost is that any shell exporting another
  path, such as a worktree, aims every script at it, and the symlink tests' setup has to be
  checked against the change.
- **Derive it from the file's own location,** as `scripts/check-python.bash` does with
  `BASH_SOURCE`. A script always acts on the checkout it lives in, so a copy works without setting
  anything, and an exported variable cannot redirect it. The cost is that running a worktree's
  copy of `u` acts on that worktree, which may or may not be wanted.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Measured (2026-10-19):* with `DOTFILES` set to a scratch copy, `generate-brewfile.bash` reported
  71 Brewfiles (the main checkout's count) and rewrote the main checkout's `Brewfile.generated`.
  With line 4 of the copy's `utils.bash` changed to `${DOTFILES:-...}`, it reported 72 and wrote
  inside the copy.
- *Sourced:* 91 files under `tools/`, `features/` and `scripts/` source `tools/bash/utils.bash`.
- *Sourced:* `tools/zsh/config/.zshrc:7` exports the same path, so interactive shells already have
  it.
- *Sourced:* `.github/workflows/test-dotfiles.yml:44` exports `DOTFILES` as the CI workspace, and
  every script that sources `utils.bash` replaces it.
- *Sourced:* `scripts/test_symlinks.py` and `scripts/check-link-scripts.bash` build a fake `HOME`
  with the repo linked at `Repos/ooloth/dotfiles`, rely on `utils.bash` deriving `DOTFILES` from
  it, and set `DOTFILES` back afterwards where they need the checkout's own paths.
- *Reasoned:* #193's planned check runs each project command against the real
  `tools/macos/utils.bash`. Those commands source `tools/bash/utils.bash`, so under the current
  override the check needs the same fake-`HOME` setup as `scripts/check-link-scripts.bash`.
