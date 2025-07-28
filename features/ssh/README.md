# SSH Feature

This module handles SSH key generation, configuration, and agent setup for the dotfiles installation.

## Structure

```
ssh/
├── install.bash    # Main installation script
├── utils.bash      # Utility functions for SSH operations
├── tests/          # Feature tests
└── README.md       # This file
```

## Installation

The installation script:
1. Generates SSH keys if not present
2. Creates/updates SSH config file
3. Adds keys to ssh-agent
4. Adds keys to macOS Keychain (on macOS)

## Configuration

The script uses these environment variables:
- `DOTFILES` - Path to dotfiles directory (default: `$HOME/Repos/ooloth/dotfiles`)

## Migration Status

This feature has been migrated to the new architecture. During the transition:
- Old location: `bin/install/ssh.bash` and `lib/ssh-utils.bash`
- New location: `features/ssh/`
- Both locations work during migration