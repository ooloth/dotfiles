# Contributing

## Check a change

```sh
shellcheck path/to/changed.bash               # every changed *.sh and *.bash file
bash scripts/check-link-scripts.bash          # every link.bash writes nothing in check mode
uv run tools/agents/check-skills.py           # every shared skill's frontmatter parses
bash scripts/check-python.bash                # ruff, ruff format and ty over every Python file
uv run --with pytest pytest --import-mode=importlib tools/agents/config/skills  # skill tests
uv run scripts/check-docs.py                  # Markdown prose wraps at 100 columns; see the script
uv run scripts/test_check_docs.py             # the docs checker's own tests
```

Expect all of them to pass. CI runs the same commands: shellcheck and the link check in
`.github/workflows/test-dotfiles.yml`, the skills check and skill tests in `test-claude-skills.yml`,
the Python checks in `check-python.yml`, and the docs checker and its tests in `check-docs.yml`.

Each check fails when it finds nothing to check: pytest exits 5 when it collects no tests, and
`check-python.bash` refuses a path with no Python files. A new check keeps that property.

On a work laptop, uv installs packages through the work Artifact Registry index set in
`~/.config/uv/uv.toml`. A 403 from `python.pkg.dev` means the Application Default Credentials
belong to an account that cannot read that registry. Run `gcloud auth application-default login`
with the internal work account. Do not point uv at public PyPI instead, because the managed config
blocks that fallback on purpose.

Shellcheck settings live in `.shellcheckrc`, not in disable comments. Run it only on `*.sh` and
`*.bash` files.

Then run what you changed. Tests passing is not evidence that it works:

- **A `link.bash`:** run `symlinks`, then `dcheck`, and read the line for each link.
- **An `update.bash`:** run `u <tool>` and check its exit status with `echo $?`.
- **A shell function or alias:** open a new shell and call it.
