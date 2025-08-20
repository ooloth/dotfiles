# Homebrew Feature

This module handles Homebrew package manager installation, package management, and configuration for the dotfiles setup.

## Structure

```
homebrew/
├── install.bash       # Main installation script  
├── utils.bash         # Bash utility functions for Homebrew operations
├── utils.zsh          # Zsh utility functions for Homebrew operations
├── config/
│   ├── Brewfile       # Homebrew package definitions
│   └── Brewfile.lock.json  # Locked package versions
├── tests/             # Feature tests
└── README.md          # This file
```

## Installation

The installation script:
1. Installs Homebrew if not present
2. Updates Homebrew to latest version
3. Installs packages from Brewfile
4. Cleans up old/unused packages

## Configuration

The script uses these environment variables:
- `DOTFILES` - Path to dotfiles directory (default: `$HOME/Repos/ooloth/dotfiles`)

## Package Management

Homebrew packages are defined in `config/Brewfile` which includes:
- Command line tools and utilities
- Applications via Homebrew Cask
- Mac App Store applications
- Font installations

## Migration Status

This feature is being migrated to the new architecture. During the transition:
- Old location: `lib/homebrew-utils.bash`, `lib/homebrew-utils.zsh`, `@common/Brewfile`
- New location: `features/homebrew/`
- Both locations work during migration
