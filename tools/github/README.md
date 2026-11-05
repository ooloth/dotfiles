# GitHub

`Brewfile` installs `gh`, and `link.bash` links `config/config.yml` to `~/.config/gh`.

## Repo security settings

`repo_settings.py` holds my repos to one baseline of security and dependency settings: Dependabot
alerts and security updates, a read-only default workflow token, no PR approval by Actions,
branch deletion on merge, and actions pinned to a commit SHA once every workflow pins them. A
public repo also gets secret scanning, push protection, private vulnerability reporting and
auto-merge. The script's docstring has the details.

```sh
uv run tools/github/repo_settings.py --check hub dotfiles   # report what differs, change nothing
uv run tools/github/repo_settings.py --apply hub dotfiles   # change it, then read it back
```

A bare name means one of mine, so `hub` is `ooloth/hub`. `--check` exits 1 when any repo differs.
It needs `gh` signed in as the owner of the repos. Nothing runs it on a schedule yet
([#252](https://github.com/ooloth/dotfiles/issues/252)).

The tests are in `tests/test_repo_settings.py`.
