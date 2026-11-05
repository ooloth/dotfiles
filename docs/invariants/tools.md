# Tools

Facts about how `tools/{name}/` directories actually work — properties
this repo's install/update automation and symlink model depend on, not
observations about typical practice.

- The scripts target macOS, and CI runs them on `macos-latest`, but `tools/bash/utils.bash` and
  every `link.bash` also run on Debian Linux with GNU coreutils. `.agents/setup` runs
  `tools/agents/link.bash` in every new Amp orb on this project, and agents there run
  `scripts/check.bash`, whose `scripts/checks/link-scripts.bash` runs every `link.bash`. So they use
  flags both BSD and GNU tools accept (no `ln -w`), and call macOS-only commands such as
  `/usr/sbin/networksetup` only after checking they exist.
- Every tool lives in its own `tools/{name}/` directory. `tools/@new/` is
  the template for creating one; `tools/@archive/` holds deprecated ones —
  neither is a real tool.
- A tool's config files live in `tools/{name}/config/`. The install/update
  automation and every `link.bash` depend on this path.
- Config files meant to live at a canonical filesystem location are
  symlinked — never copied — into place. Editing the repo copy must be
  enough to change the live config; a copy would silently stop reflecting
  edits.
- With `DOTFILES_CHECK=true`, a `link.bash` reports link status and writes nothing: no link,
  file or directory is created, replaced or removed. `dcheck` and `u`'s final check depend on
  this to be read-only. `scripts/checks/link-scripts.bash` checks every `link.bash` in CI.
- A script run from any checkout of this repo, such as a worktree or a scratch copy, sources,
  reads and writes that checkout's files. `tools/bash/utils.bash` sets `DOTFILES` from its own
  location, ignoring any value the caller exported, and every bash script directly in a
  `tools/<tool>/` or `features/<feature>/` folder sources it by a path relative to itself before
  reading `DOTFILES`.
  `tools/bash/tests/test_dotfiles_location.py` checks every script.
- Every link the link step makes in `$HOME` names a file under `~/Repos/ooloth/dotfiles`
  (`DOTFILES_INSTALL` in `tools/bash/utils.bash`), and `private.env` is read from there. Run from
  any other checkout, the link step, check mode included, changes nothing in `$HOME` and says why.
  A test or an Amp orb links from another checkout by giving it a `HOME` whose
  `Repos/ooloth/dotfiles` resolves to that checkout.
- `.github/workflows/check.yml` and `.agents/setup` install the same tools for the checks, beyond
  what each platform already ships, such as the zsh, luajit and newer jq that `.agents/setup` adds
  for an Amp orb, so `scripts/check.bash` passes in CI and in an Amp orb. A tool a check starts or
  stops needing changes in both, and in its tool's Brewfile.
- A `preflight.bash` only checks and changes nothing. `features/update/preflight.bash` runs
  every one before `u` updates anything, so a check that wrote something would write on every
  run, including runs that then stop.
- A tool's tests are `tools/{name}/tests/test_*.py`, and a feature's are
  `features/{name}/tests/test_*.py`. `scripts/checks/tests.bash` runs them, the tests in
  `scripts/*/tests/` and a skill's own tests under `tools/agents/config/skills/` in one pytest
  run, in CI and from `scripts/check.bash`, and fails on a `test_*.py` placed directly in
  `tools/{name}/` or `features/{name}/`.
- A `config/` directory with no `link.bash` is legitimate only for two
  reasons: the config is consumed directly by that tool's own install
  logic instead of being placed under `$HOME` (e.g. macOS defaults,
  applied via `defaults write`), or the config has no filesystem target at
  all and is meant for manual copy-paste elsewhere (e.g. a browser
  extension's settings).
- `tools/macos/utils.bash` keeps a `COMPUTER` its caller already set, and asks `networksetup` for
  the machine only when `COMPUTER` is unset or empty. A test of a script that branches on
  `is_work`, `is_air` or `is_mini` chooses the machine by setting `COMPUTER`, because
  `networksetup` is called by absolute path and no stub on `PATH` reaches it.
  `tools/macos/tests/test_utils.py` checks both halves.
