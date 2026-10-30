# Contributing

## Check a change

```sh
check                                         # from the repo root; same as bash scripts/check.bash
```

Expect it to pass. It runs five categories, fastest first, and stops at the first that fails. To
run one on its own, run its script:

```sh
bash scripts/checks/formatting.bash           # ruff format
uv run scripts/checks/docs.py                 # Markdown prose wraps at 100 columns; see the script
bash scripts/checks/types.bash                # ty
bash scripts/checks/linting.bash              # ruff check, shellcheck, zsh utils parse as bash, skills
bash scripts/checks/tests.bash                # link.bash check mode alongside one pytest run of every test
```

The tests run across every core with pytest-xdist and print the ten slowest, and `check` prints
how long each category took. pytest ignores a test file's inline script header, so `tests.bash`
installs what `scripts/checks/test-dependencies.py` reads from the headers. Declare a test's
dependencies in its header and nowhere else; it still runs on its own with `uv run <file>`.

A test that puts a stub or fake tool on `PATH` writes it once per test class or module, in a folder
it then makes read-only, and keeps everything each test changes in that test's own temporary
directory. On a work laptop a newly written executable takes about 200 ms more to start the first
time, so a stub written for every Hypothesis example can cost more than the script under test.
`tools/claude/tests/test_cc.py` shows the pattern in `write_stubs`.

CI runs the same five scripts in the same order, one step each, in `.github/workflows/check.yml`.
A category is named for the kind of check, not the language, so a tool for a new language joins
the matching script. Each check fails when it finds nothing to check: pytest exits 5 when it
collects no tests, and each script refuses to run with no files of the kind it checks. A new check
keeps that property.

On a work laptop, uv installs packages through the work Artifact Registry index set in
`~/.config/uv/uv.toml`, which authenticates with Application Default Credentials. Before running
`check`, log in:

```sh
gcloud auth login <you>@recursion.com --update-adc
```

Without it, uv fails with `Incomplete credentials` or a 403 from `python.pkg.dev`. Do not
point uv at public PyPI instead, because the managed config blocks that fallback on purpose.

Shellcheck settings live in `.shellcheckrc`, not in disable comments. Run it only on `*.sh` and
`*.bash` files.

Then run what you changed. Tests passing is not evidence that it works:

- **A `link.bash`:** run `symlinks`, then `dcheck`, and read the line for each link.
- **An `update.bash`:** run `u <tool>` and check its exit status with `echo $?`.
- **A shell function or alias:** open a new shell and call it. An agent's shell does not set up the
  aliases, so there a name such as `cc` finds a program on `PATH` instead. Start a clean
  interactive zsh, keeping the variables Claude Code needs to find its login:
  `env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" TERM=xterm zsh -ic '<alias> <args>'`.
