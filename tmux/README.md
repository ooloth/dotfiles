# Tmux Feature

Self-contained tmux installation and configuration management for the dotfiles repository.

## Overview

This feature handles:
- Installing tmux plugin manager (tpm)
- Installing and updating tmux plugins
- Managing tmux configuration
- Optional terminfo configurations for improved terminal compatibility

## Files

- `install.bash` - Main installation script for tmux and tpm
- `update.bash` - Update script for tmux plugins and configuration
- `utils.bash` - Shared utility functions for tmux management
- `config/` - Tmux configuration files
  - `tmux.conf` - Main tmux configuration
  - `battery.sh` - Battery status script for tmux status bar
  - `gitmux.conf` - Git status configuration for tmux
  - `tmux.terminfo` - Terminal info definitions for tmux
  - `xterm-256color-italic.terminfo` - Extended terminal info for italic support
- `tests/` - Test files for the tmux feature
  - `test-tmux-installation.bats` - Tests for installation functionality
  - `test-tmux-utils.bats` - Tests for utility functions

## Usage

### Installation

Install tmux plugin manager and plugins:

```bash
./tmux/install.bash
```

### Updates

Update tmux plugins and reload configuration:

```bash
./tmux/update.bash
```

## Requirements

- `tmux` must be installed (typically via Homebrew: `brew install tmux`)
- `git` for cloning tpm repository
- Network access to clone tpm from GitHub

## Configuration

The tmux configuration is located in `config/tmux.conf` and includes:
- Plugin definitions for tpm
- Key bindings and tmux behavior
- Status bar configuration with git integration
- Color scheme and visual settings

### Plugins

Plugins are managed by tpm (tmux plugin manager). The configuration defines which plugins to install, and this feature handles the installation and updating process automatically.

## Testing

Run the test suite:

```bash
# Install bats-core if not available
brew install bats-core

# Run tmux feature tests
bats tmux/tests/
```

Tests cover:
- tpm installation and detection
- Plugin management operations
- Configuration validation
- Utility function behavior

## Migration Notes

This feature replaces the previous zsh-based tmux scripts:
- `bin/install/tmux.zsh` → `tmux/install.bash`
- `bin/update/tmux.zsh` → `tmux/update.bash`

The bash implementation provides:
- Self-contained functionality (no external lib dependencies)
- Improved error handling and validation
- Comprehensive testing coverage
- Better modularity and maintainability

## Troubleshooting

### Common Issues

1. **tpm installation fails**
   - Check network connectivity
   - Verify SSH access to GitHub
   - Ensure `~/.config/tmux/plugins/` directory is writable

2. **Plugin installation fails**
   - Verify tpm is installed correctly
   - Check tmux configuration syntax
   - Ensure tmux is not running during initial installation

3. **Configuration reload fails**
   - Verify tmux is running: `tmux list-sessions`
   - Check tmux config syntax: `tmux source ~/.config/tmux/tmux.conf`
   - Restart tmux if issues persist

### Manual Operations

If automatic operations fail, you can manually:

```bash
# Install tpm manually
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install plugins manually (from within tmux)
# Press prefix + I

# Update plugins manually (from within tmux)
# Press prefix + U

# Reload tmux config
tmux source ~/.config/tmux/tmux.conf
```
