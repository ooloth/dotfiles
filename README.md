# My dotfiles

A highly opinionated development environment configuration for macOS.

## ⚠️ Important Disclaimer

**This repository represents my personal preferences and workflow.** It's constantly evolving based on my needs and experiments. I strongly encourage you to:

- **Fork this repo** and customize it to your preferences
- **Browse and borrow** individual configurations that interest you
- **Use it as inspiration** for your own dotfiles

Unless you share my exact preferences (unlikely!), directly using this configuration will probably frustrate you. You've been warned! 😊

## Philosophy

These dotfiles reflect years of iteration on my development workflow. They're optimized for:

- Keyboard-driven workflows (minimal mouse usage)
- Terminal-first development
- Fast navigation and editing
- Consistent keybindings across tools
- Reducing context switching

The setup is intentionally opinionated and may include experimental configurations.

## What's Included

### Core Tools

- **Shell**: [zsh](https://www.zsh.org/) with [Starship](https://starship.rs/) prompt
- **Terminal Multiplexer**: [tmux](https://github.com/tmux/tmux) with custom keybindings
- **Editor**: [Neovim](https://neovim.io/) with extensive plugin configuration
- **Terminal Emulators**: [Kitty](https://sw.kovidgoyal.net/kitty/), [Alacritty](https://alacritty.org/), [Ghostty](https://ghostty.org/)
- **Version Control**: Git with [lazygit](https://github.com/jesseduffield/lazygit) and [delta](https://github.com/dandavison/delta)
- **File Manager**: [yazi](https://github.com/sxyazi/yazi)
- **Package Management**: [Homebrew](https://brew.sh/) for macOS packages

### Development Tools

- **Languages**: Node.js (via [fnm](https://github.com/Schniz/fnm)), Rust, Python (via [uv](https://github.com/astral-sh/uv)), Go
- **Containers**: Docker with [lazydocker](https://github.com/jesseduffield/lazydocker)
- **Kubernetes**: kubectl with [k9s](https://k9scli.io/)
- **Search**: [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf)

### Additional Features

- Machine-specific configurations (Personal Air, Mac Mini, Work machines)
- Automated installation and update scripts
- macOS system preferences configuration
- VS Code settings and extensions
- Custom keyboard layout (Kinesis Advantage 2)

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
   Repeat until fully updated.

## Installation

### Quick Install (Recommended)

```sh
curl -s https://raw.githubusercontent.com/ooloth/dotfiles/main/setup.zsh | zsh
```

This will:

1. Clone this repository to `~/Repos/ooloth/dotfiles`
2. Run all installation scripts in sequence
3. Set up symlinks for all configurations
4. Configure macOS system preferences

### Manual Installation

If you prefer more control:

```sh
# Clone the repository
git clone https://github.com/ooloth/dotfiles.git ~/Repos/ooloth/dotfiles
cd ~/Repos/ooloth/dotfiles

# Run the setup script
./setup.zsh

# Preview what would be installed without making changes
./setup.zsh --dry-run

# Or run individual installation scripts
cd bin/install
source ssh.zsh         # SSH keys and GitHub auth
source github.zsh      # GitHub CLI setup
source homebrew.zsh    # Homebrew and packages
source zsh.zsh         # Shell configuration
source rust.zsh        # Rust toolchain
source uv.zsh          # Python package manager
source node.zsh        # Node.js via fnm
source tmux.zsh        # tmux plugins
source neovim.zsh      # Neovim plugins
source yazi.zsh        # File manager plugins
source content.zsh     # Personal content repos
source settings.zsh    # macOS preferences
```

## After Installation

1. **Restart your terminal** for all changes to take effect
2. **Open tmux** and install plugins: Press `prefix + I` (default prefix is `Ctrl-a`)
3. **Open Neovim** and wait for plugins to install automatically
4. **Sign into applications** that require authentication

## Customization Guide (After Forking)

### Machine-Specific Configuration

The setup automatically detects machine type based on hostname:

- Machines with "Air" in the name → Personal laptop configuration
- Machines with "Mini" in the name → Home server configuration
- All others → Work machine configuration

To customize for your machines, edit the detection logic in `setup.zsh` or set the environment variables manually.

### Key Files to Customize

1. **Git Configuration**: Edit `git/config` with your information
2. **Shell Aliases**: Modify `config/zsh/aliases.zsh`
3. **Neovim**: Customize `config/nvim/init.lua`
4. **Homebrew Packages**: Edit `homebrew/config/Brewfile`
5. **macOS Preferences**: Adjust `macos/macos-defaults`

### Adding Your Own Tools

1. Add Homebrew packages to `homebrew/config/Brewfile`
2. Add configuration files to `config/<tool-name>/`
3. Add symlinks in `bin/update/symlinks.zsh`
4. Run `symlinks` to create the links

## Updating

```sh
# Update everything (recommended)
u

# Or run individual update scripts directly
$DOTFILES/bin/update/homebrew.zsh   # Update Homebrew packages
$DOTFILES/bin/update/npm.zsh        # Update global npm packages
$DOTFILES/bin/update/neovim.zsh     # Update Neovim plugins
$DOTFILES/bin/update/tmux.zsh       # Update tmux plugins
$DOTFILES/bin/update/rust.zsh       # Update Rust toolchain
$DOTFILES/bin/update/symlinks.zsh   # Recreate symlinks
```

The `u` function runs all updates and reloads your shell.

## Troubleshooting

### Symlinks Already Exist

The installation preserves existing files. To replace them:

1. Back up the existing file
2. Remove it manually
3. Run `symlinks`

### Command Not Found

Ensure `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel) is in your PATH.

### Neovim Plugins Not Loading

1. Open Neovim
2. Run `:Lazy sync`
3. Restart Neovim

### Machine Detection Not Working

Set the environment variables manually in your shell:

```sh
export IS_WORK=true   # or false
export IS_AIR=true    # or false
export IS_MINI=true   # or false
```

## Contributing

Since these are personal dotfiles, I'm not accepting pull requests for feature additions. However, please feel free to:

- Open issues for bugs or questions
- Fork and customize for your own use
- Share your own improvements in your fork

## License

MIT - See [LICENSE.md](LICENSE.md)

## Inspiration

- [Dotfiles community](https://dotfiles.github.io/)
- [Nick Nisi's dotfiles](https://github.com/nicknisi/dotfiles)
- The many developers who share their configurations publicly
