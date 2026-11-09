# Contributing

A new script that is run, rather than sourced, is written in Python
([decision 007](docs/decisions/007-scripts-that-are-run-are-written-in-python.md)): for now a
single-file uv script, as decision 008's addendum allows until the root project exists. Two kinds
stay in shell, as decision 007 and its addendum say:

- **Scripts `u` and setup find by file name:** a tool's `install.bash`, `update.bash`, `link.bash`
  and `preflight.bash`. The runners look only for those names, so an `update.py` would never run.
- **The first step of setup on a new Mac**, which runs before Python is installed.

## Check a change

```sh
bash scripts/check.bash                       # from the repo root or a worktree
```

The `check` alias runs the same thing from the main checkout, but it picks what to run from the
folder's name, so it finds nothing in a worktree, and an agent's shell has no aliases. Expect it to
pass. It runs five categories, fastest first, and stops at the first that fails. To
run one on its own, run its script under `/bin/bash`, as `check` does, so a newer bash on `PATH`
can't pass what CI's bash 3.2 fails:

```sh
/bin/bash scripts/checks/formatting.bash      # ruff format
uv run scripts/checks/docs.py                 # Markdown prose wraps at 100 columns; see the script
/bin/bash scripts/checks/types.bash           # ty
/bin/bash scripts/checks/linting.bash         # ruff check, shellcheck, zsh utils, skills
/bin/bash scripts/checks/tests.bash           # link.bash check mode alongside one pytest run of every test
```

The tests run across every core with pytest-xdist and print the ten slowest, and `check` prints
how long each category took. pytest ignores a test file's inline script header, so `tests.bash`
installs each header with `uv run --with-requirements`, and a test file in a `tests/` folder with
no header fails the run. Declare a test's dependencies in its header and nowhere else. Every test
shares one environment, so a missing declaration shows up only when the file runs on its own with
`uv run <file>`. The tests beside a skill's scripts have no header: they run with the pytest,
hypothesis, pydantic and markdown-it-py that `tests.bash` installs for every run. This holds until
#204 creates the root project that decision 008 sets out, which then holds every test's
dependencies.

A test that puts a stub or fake tool on `PATH` writes it once per test class or module, in a folder
it then makes read-only, and keeps everything each test changes in that test's own temporary
directory. On a work laptop a newly written executable takes about 200 ms more to start the first
time, so a stub written for every Hypothesis example can cost more than the script under test.
`tools/claude/tests/test_cc.py` shows the pattern in `write_stubs`.

CI runs the same five scripts in the same order, one step each, in `.github/workflows/check.yml`.
A category is named for the kind of check, not the language, so a tool for a new language joins
the matching script. Each check fails when it finds nothing to check: pytest exits 5 when it
collects no tests, and each script refuses to run with no files of the kind it checks. A new check
keeps that property, except where its input is legitimately empty on some machine: then it says it
skipped and why, as `testing.md` in the shared standards describes.

On a work laptop, uv installs packages through the work Artifact Registry index set in
`~/.config/uv/uv.toml`, which authenticates with Application Default Credentials. Before running
`check`, log in:

```sh
gcloud auth login --update-adc <you>@recursion.com
```

On the work laptop, `auth` runs this login along with the other work logins, and only for the ones
that have expired (see `features/auth/README.md`).

Without it, uv fails with `Incomplete credentials` or a 403 from `python.pkg.dev`. The managed
config names that index as the only default, so uv resolves packages only through it unless a
project names another index, and an install from a lock fetches the URLs the lock records. The
maintainer allows the packages this repo's Python project depends on to come from PyPI on a work
laptop, as long as every one of them is a public package. Which command and `uv.lock` option the
project uses to get them is open in
[what-command-starts-the-repos-python.md](docs/questions/what-command-starts-the-repos-python.md).

Shellcheck settings live in `.shellcheckrc`, not in disable comments. Run it only on `*.sh` and
`*.bash` files.

Then run what you changed. Tests passing is not evidence that it works:

- **A `link.bash`:** from the main checkout, run `bash features/update/symlinks.bash <tool>`, then
  `bash features/check/dotfiles.bash`, and read the line for each link. From a worktree, a
  `link.bash` refuses to link, so run it with a temporary `HOME` whose `Repos/ooloth/dotfiles` links
  to the worktree, then list the links under `$h`:

  ```bash
  h="$(mktemp -d)" && mkdir -p "$h/Repos/ooloth" && ln -s "$PWD" "$h/Repos/ooloth/dotfiles"
  HOME="$h" bash tools/<tool>/link.bash
  ```

- **An `update.bash`:** run `u <tool>` and check its exit status with `echo $?`. `u` runs the main
  checkout's scripts, starting with the tool's preflight, so from a worktree run
  `bash features/update/preflight.bash <tool> && bash tools/<tool>/update.bash`. That
  runs the real update on this machine. If the script has a link step, the link step is skipped
  with a note and the rest of the update runs.
- **The Claude Code status line:** from the checkout you changed, pipe it a payload Claude Code
  sent, with its reset times moved after now, because the line leaves out a window whose reset has
  passed:

  ```bash
  jq --arg d "$PWD" '.workspace.current_dir = $d
    | .rate_limits.five_hour.resets_at = (now + 3 * 3600)
    | .rate_limits.seven_day.resets_at = (now + 4 * 86400)' \
    tools/claude/tests/fixtures/statusline-payload.json | COLUMNS=120 tools/claude/statusline.py
  ```

  A session's own status line runs the main checkout's copy, because `settings.json` names it by
  that path, so a change in a worktree shows there only once it reaches the main checkout.
- **The planning replay (`tools/claude/replay.py`):** `uv run tools/claude/replay.py grades` reads
  only the replay folders, and `uv run tools/claude/tests/test_replay.py` runs `replay plan` end to
  end with fake `gh` and `claude` commands. Those fakes can't show what the real sandbox refuses,
  so a change to the sandbox settings, the session's command, the canary, the `gh` stand-in
  (`replay_gh.py`) or the `mktemp` wrapper needs a real run of
  `uv run tools/claude/replay.py plan <owner/repo#n> --run <k>`, from the checkout that holds the
  change, since the `replay` alias runs the main checkout's copy. It first runs a short Haiku
  canary, then a headless Opus session that usually takes under an hour, stops at three, and draws
  on the subscription's usage limits, so ask before starting one. Run it in a tmux window, since it
  outlasts a foreground command, and with `XDG_STATE_HOME="$(mktemp -d)"`, so the proof run stays
  out of the replays `replay grades` counts. A canary the sandbox didn't refuse stops the run before
  any folder exists, with a message naming the check. Otherwise read the folder it prints,
  `audit.md` first.
- **A shell function or alias:** open a new shell and call it. An agent's shell does not set up the
  aliases, so there a name such as `cc` finds a program on `PATH` instead. Start a clean
  interactive zsh, keeping the variables Claude Code needs to find its login:
  `env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" TERM=xterm zsh -ic '<alias> <args>'`.
