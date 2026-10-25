# Tools

Facts about how `tools/{name}/` directories actually work — properties
this repo's install/update automation and symlink model depend on, not
observations about typical practice.

- The scripts and their tests target macOS, and CI runs them on `macos-latest`.
  `tools/bash/utils.bash` sources `tools/macos/utils.bash`, which calls
  `/usr/sbin/networksetup`, and `symlink()` calls BSD `ln -w`. On Linux, such as an Amp orb,
  `scripts/checks/link-scripts.bash` and the tests in `features/update/tests/` fail for that
  reason alone.
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
- A `preflight.bash` only checks and changes nothing. `features/update/preflight.bash` runs
  every one before `u` updates anything, so a check that wrote something would write on every
  run, including runs that then stop.
- A tool's tests are `tools/{name}/tests/test_*.py`, and a feature's are
  `features/{name}/tests/test_*.py`. `scripts/checks/tests.bash` runs only those paths and
  `scripts/*/tests/`, in CI and from `scripts/check.bash`, and fails on a `test_*.py` placed
  directly in `tools/{name}/` or `features/{name}/`. Test files deeper in a tool's subtree, such
  as a skill's own tests under `tools/agents/config/skills/`, run through pytest in the same
  script instead.
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
