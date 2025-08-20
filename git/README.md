# Git Feature

This module handles Git configuration and GitHub integration for the dotfiles setup.

## Structure

```
git/
├── install.bash       # Main installation script
├── utils.bash         # Utility functions for Git/GitHub operations
├── config/
│   ├── config         # Main Git configuration
│   ├── config.work    # Work-specific Git configuration
│   └── ignore         # Global Git ignore patterns
├── tests/             # Feature tests
└── README.md          # This file
```

## Installation

The installation script:

1. Configures Git global settings
2. Sets up work-specific Git configuration (if on work machine)
3. Configures global Git ignore file
4. Validates Git configuration

## Configuration

The script uses these environment variables:

- `DOTFILES` - Path to dotfiles directory (default: `$HOME/Repos/ooloth/dotfiles`)
- `IS_WORK` - Boolean flag for work machine configuration

## Git Configuration

- **Main config:** Standard Git settings for personal development
- **Work config:** Additional settings that override main config on work machines
- **Global ignore:** Common patterns to ignore across all repositories

## GitHub Integration

Includes utilities for:

- GitHub CLI configuration
- Repository management
- Authentication setup

## Migration Status

This feature is being migrated to the new architecture. During the transition:

- Old location: `config/git/`, `lib/github-utils.bash`
- New location: `git/`
- Both locations work during migration

