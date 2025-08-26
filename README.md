# My dotfiles

A highly opinionated development environment configuration for macOS.

## ⚠️ Disclaimer

I update these configurations often as my preferences change. Don't expect stability! Use this repo as inspiration and feel free to fork and customize it.

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
