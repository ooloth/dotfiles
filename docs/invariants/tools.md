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
- A script another program runs by its path in the repo, such as `tools/claude/statusline.py` and
  `tools/claude/notify.bash` that `settings.json` runs, sits beside `config/`, not in it, unless it
  belongs to a skill, which keeps its scripts in its own folder under `tools/agents/config/skills/`.
- Config files meant to live at a canonical filesystem location are
  symlinked — never copied — into place. Editing the repo copy must be
  enough to change the live config; a copy would silently stop reflecting
  edits.
- With `DOTFILES_CHECK=true`, a `link.bash` reports link status and writes nothing: no link,
  file or directory is created, replaced or removed. `dcheck` and `u`'s final check depend on
  this to be read-only. `scripts/checks/link-scripts.bash` checks every `link.bash` in CI.
- A bash script directly in a `tools/<tool>/` or `features/<feature>/` folder, `tools/@new/`
  included, run from any checkout of this repo such as a worktree or a scratch copy, sources, reads
  and writes that checkout's files. The one exception is `private.env`, which comes from the
  install (next item). `tools/bash/utils.bash` sets `DOTFILES` from its own location, ignoring any
  value the caller exported, and each such script sources it by a path relative to itself before
  reading `DOTFILES`. Outside this rule are the files `utils.bash` itself sources (`tools/bash/`
  and `tools/macos/utils.bash`), `tools/amp/workspace-resume.bash` (which sets up the install),
  the setup `.zsh` files and the `wip/` drafts. `tools/bash/tests/test_dotfiles_location.py`
  checks that each script in scope sources `utils.bash` that way before anything else, assigns no
  `DOTFILES`, names no install path, and runs no `link.bash` directly from an `update.bash` or
  `install.bash`.
- Every link the link step makes in `$HOME` names a file under `~/Repos/ooloth/dotfiles`
  (`DOTFILES_INSTALL` in `tools/bash/utils.bash`), and `private.env` is read from there. Run from
  any other checkout, the link step, check mode included, changes nothing in `$HOME` and says why.
  An `update.bash` or `install.bash` reaches its link step only through `run_link_step`, which
  from another checkout skips it with a note and lets the rest of the script run. A test or an Amp
  orb links from another checkout by giving it a `HOME` whose `Repos/ooloth/dotfiles` resolves to
  that checkout.
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
- A Brewfile learns which Mac it runs on only from `tools/macos/computer.rb`, loaded with
  `require_relative "../macos/computer"`, and asks `air?`, `mini?` or `work?`. Homebrew's
  `bin/brew` re-runs itself under `env -i`, keeping only a short list of variables and every
  `HOMEBREW_*` one, so `COMPUTER` never reaches a Brewfile. The helper therefore asks
  `networksetup` itself, by the same rule as `utils.bash`: `Air` and `Mini` are personal Macs and
  every other name is a work Mac. `tools/macos/tests/test_computer.py` checks four things. The
  helper and `shell.zsh` map the same names to the same machines, and the helper agrees with
  `utils.bash` on the Mac the tests run on. Every Brewfile evaluates on each machine, on its own
  and combined. Every Brewfile that asks `air?`, `mini?` or `work?` loads the helper. No Brewfile
  reads `networksetup`, `scutil`, `hostname` or `ENV`.
- A planning replay (`tools/claude/replay.py`) sees its ticket only as it stood when planning began.
  Its clone holds only commits made before then, its `gh` stand-in serves the title and body as they
  stood then plus the comments the replay itself posts, and its sandbox reads no other checkout of
  the ticket's repo and no session transcripts. What it sees as it is today is the agent harness and
  the dotfiles folders the Bash allow-list opens through links, such as `tools/git/config/`, all in
  the install at `~/Repos/ooloth/dotfiles` whichever checkout runs `replay.py`, so a ticket is
  refused when a dotfiles commit made after its planning began names it and changes one of those
  paths. A change there that names no ticket still reaches the replay. The session loads the clone's
  own project instructions and skills, with every hook turned off, and a ticket whose clone's
  committed project settings hold a key other than `attribution`, `hooks` or
  `enableAllProjectMcpServers` is refused. Before each replay, a canary session shows that two
  forbidden reads, three forbidden writes and a forbidden connection are each refused with that
  fence's own message, that a write in scratch and a `gh` call work, that no hook runs, and that the
  clone's `CLAUDE.md` loads. The Edit and Write tools reach only the working folders, and never the
  home folder. `tools/claude/tests/test_replay.py` checks each part.
