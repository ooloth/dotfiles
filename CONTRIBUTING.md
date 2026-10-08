# Contributing

## Check a change

```sh
shellcheck path/to/changed.bash               # every changed *.sh and *.bash file
bash scripts/check-link-scripts.bash          # every link.bash writes nothing in check mode
bash scripts/check-project-commands.bash      # every project command exits 1 when no case matches
uv run tools/agents/check-skills.py           # every shared skill's frontmatter parses
uv run scripts/check-docs.py                  # Markdown prose wraps at 100 columns; see the script
uv run scripts/test_check_docs.py             # the docs checker's own tests
```

Expect all of them to pass. CI runs the same commands: shellcheck, the link check and the project
command check in `.github/workflows/test-dotfiles.yml`, the skills check in
`test-claude-skills.yml`, and the docs checker and its tests in `check-docs.yml`.

Shellcheck settings live in `.shellcheckrc`, not in disable comments. Run it only on `*.sh` and
`*.bash` files.

Then run what you changed. Tests passing is not evidence that it works:

- **A `link.bash`:** run `symlinks`, then `dcheck`, and read the line for each link.
- **An `update.bash`:** run `u <tool>` and check its exit status with `echo $?`.
- **A shell function or alias:** open a new shell and call it.
