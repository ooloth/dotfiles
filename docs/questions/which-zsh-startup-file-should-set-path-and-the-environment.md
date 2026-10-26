---
updated: 2026-10-25
update_when: a zsh startup file changes what it sets, or another program is found that starts zsh without reading .zshrc
decays: fast
status: open
---

# Which zsh startup file should set PATH and the environment?

## Why it matters

`tools/zsh/config/core.zsh` sets PATH (including `brew shellenv`), `EDITOR`, `XDG_CONFIG_HOME` and
the history variables, and only `.zshrc` sources it. zsh reads `.zshrc` only in interactive shells.
Any program that starts a command through a zsh that isn't interactive gets none of it.

Rex is one such program. It runs a command, such as `rex run -- lazygit` or a block's `command`
option, through a login shell that isn't interactive, so the command can't find anything installed
by Homebrew. Programs that do start get the wrong config: lazygit, for example, looks for its config
in `~/Library/Application Support` instead of `~/.config/lazygit`. The `lazygit` action in
`tools/rex/config/init.lua` works around this by starting lazygit through `zsh -i -c`. That costs a
full interactive startup on every press, and every later command Rex runs needs the same
workaround.

## What would settle it

A list of the programs that start zsh on these machines, and what each one reads: Rex, tmux,
Ghostty, Claude Code, editors, scripts with a zsh shebang. Then a measurement of shell startup time
for each option, and a check that PATH order stays correct. `core.zsh` notes that `brew shellenv`
moves `/opt/homebrew/bin` to the front, so anything that must come before it, such as fnm's shim,
is added after it.

## Resolves into

A decision record in `../decisions/`. If the setup moves, the `lazygit` action goes back to running
`lazygit` directly, and its test's expected command changes with it.

## Source

Raised on 2026-10-25, while adding the `cmd+g` lazygit binding to `tools/rex/config/init.lua`. The
first live run showed `zsh:1: command not found: lazygit` in the new pane.

## Options

- **Keep everything in `.zshrc` (current).** Shell scripts and other shells that aren't interactive
  start fast and see nothing personal. The cost is that every program that runs commands without an
  interactive shell needs its own workaround, as the Rex action does now.
- **Move the environment setup to `.zprofile`.** zsh reads `.zprofile` in login shells only, and
  Rex starts commands through a login shell, so Rex commands would get the same environment as the
  panes. Scripts that aren't run through a login shell still wouldn't see any of it. The cost is
  splitting `core.zsh` into an environment part and an interactive part, plus keeping the PATH order
  right across two files.
- **Move the environment setup to `.zshenv`.** Every zsh gets the environment, including scripts
  and `zsh -c`. That is the broadest fix and the most common advice for PATH. The cost is that
  every script with a zsh shebang runs `brew shellenv` and the rest, which adds startup time and
  makes scripts depend on personal setup.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Measured (2026-10-25, this Mac):* a lazygit block that Rex started with no `shell` option
  showed `zsh:1: command not found: lazygit`. The same block, started with `shell = "none"` and
  `/opt/homebrew/bin/zsh -i -c lazygit`, drew its screen about 600 ms after the action ran, in the
  pressed pane's directory.
- *Measured (2026-10-25, this Mac):* `env -i HOME=$HOME TERM=xterm-256color
  /opt/homebrew/bin/zsh -i -c exit` took 0.57 s once and 0.28 s twice.
- *Measured (2026-10-26, this Mac):* the same command took 0.27 to 0.28 s over five runs. Moving
  the environment out of `.zshrc` would save that much on every `cmd+g` in Rex, because lazygit
  would no longer need an interactive shell.
- *Measured (2026-10-26, this Mac):* an `xtrace` of that startup showed most of the time going to
  subprocesses that `tools/*/shell.zsh` runs on every start. `uv` completions took about 84 ms (the
  `eval` of `uv generate-shell-completion zsh` plus `uvx --generate-shell-completion zsh`), `op
  completion zsh` 45 ms, `/usr/sbin/networksetup -getcomputername` 25 ms (run twice),
  `brew shellenv` 18 ms and `ty generate-shell-completion zsh` 6 ms. The trace adds its own
  overhead, so the times are relative.
- *Measured (2026-10-26, this Mac):* `compinit` with an up-to-date dump took 16 ms, and
  `compinit -C` took 9 ms. Rebuilding the dump took 189 ms. `~/.zcompdump`'s `#files:` count
  changed from 1138 to 1091 between two shells started with different environments, which
  suggests that shells with different `fpath` values rebuild the dump in turn. This is not yet
  confirmed.
- *Sourced:* `.zshenv` runs `unsetopt GLOBAL_RCS`, so zsh skips `/etc/zprofile` and macOS's
  `path_helper`. The usual warning that `path_helper` reorders a PATH set in `.zshenv` doesn't
  apply to this setup.
- *Sourced:* commit `e19e7350` ("zshenv: move most variables to zshrc", 2025-05-25) moved the
  variables out of `.zshenv`. Its message records no reason.
- *Unverified:* earlier research found `.zshrc` the better place for these variables. Neither the
  research nor its sources are recorded.
