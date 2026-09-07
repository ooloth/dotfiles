# My dotfiles

A highly opinionated development environment for macOS, including shell, editor and tool
configuration plus the agent skills and engineering workflows I use every day.

> [!WARNING]
> I update these configurations often as my preferences change. I recommend you treat this repo as
> inspiration and fork and customize it to your liking if you're looking for stability.

## 🤖 Agent-assisted development

I've been experimenting with coding agents as a way to make good engineering practices explicit and
repeatable, rather than just using them to generate code.

Some of the skills I've found most useful:

- Design — compare possible approaches, design the type progression and derive a test plan before implementation
- Discuss — explore a problem and decide what to do without changing anything
- Review — review changes systematically and iterate until the important issues are resolved
- Standards — review a project against the engineering standards I use across projects
- Invariants — make sure an agent knows about and applies the guarantees a project depends on
- PR workflows — create and review pull requests using repeatable checks and conventions

They're opinionated and evolving because they're mostly an attempt to encode how I already like to work.

## What's Included

```
features/
├── install/  # install one or more tools
├── setup/    # bootstrap a new machine
├── update/   # update one or more tools
tools/
├── bash/
├── eza/
├── gh/
├── ghostty/
├── git/
├── homebrew/
├── kitty/
├── lazydocker/
├── lazygit/
├── macos/
├── neovim/
├── node/
├── powerlevel10k/
├── rust/
├── sesh/
├── ssh/
├── surfingkeys/
├── tmux/
├── uv/
├── visidata/
├── vscode/
├── yazi/
└── zsh/
```

## Prerequisites

1. Connect to the internet
2. Sign into iCloud in System Preferences (required for App Store installations via `mas`)
3. Install Xcode Command Line Tools:
   ```sh
   xcode-select --install
   ```
4. Update macOS:
   ```sh
   sudo softwareupdate --install --all --restart
   ```

## Installation

```sh
curl -s https://raw.githubusercontent.com/ooloth/dotfiles/main/features/setup/setup.zsh | zsh
```

This will:

1. Clone this repository to `~/Repos/ooloth/dotfiles`
2. Run all installation scripts in sequence
3. Set up symlinks for all configurations
4. Configure macOS system preferences

## Checking

```sh
dcheck        # verify symlinks and critical tool presence
```

`dcheck` is a read-only health check. It reports `OK`, `MISSING`, or
`WRONG TARGET` for every managed symlink and confirms that critical
tools are installed. Exits nonzero if anything is wrong.

## Updating

```sh
u             # update everything
u "homebrew"  # update one tool
symlinks      # update symlinks
```

The `u` function runs all updates and reloads your shell.

## Contributing

I'm not accepting pull requests, but please feel free to...

- Open issues to discuss bugs, questions or suggestions
- Fork and customize this project however you like
- Demonstrate improvement opportunities using your fork

## Inspiration

- [Dotfiles community](https://dotfiles.github.io/)
- [Nick Nisi's dotfiles](https://github.com/nicknisi/dotfiles)
- The many developers who share their configurations publicly
