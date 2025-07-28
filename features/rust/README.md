# Rust Feature

This module handles Rust installation and management via rustup for the dotfiles setup.

## Structure

```
rust/
├── install.bash       # Main installation script
├── update.bash        # Update script for Rust toolchain
├── utils.bash         # Utility functions for Rust operations
├── config/            # Configuration files (if needed)
├── tests/             # Feature tests
└── README.md          # This file
```

## Installation

The installation script:
1. Sets up custom CARGO_HOME and RUSTUP_HOME paths
2. Checks if Rust is already installed
3. Downloads and installs rustup if not present
4. Validates the installation

## Update

The update script:
1. Checks if rustup is available
2. Installs Rust if missing
3. Updates the Rust toolchain to latest version
4. Validates the updated installation

## Configuration

The script uses these environment variables:
- `DOTFILES` - Path to dotfiles directory (default: `$HOME/Repos/ooloth/dotfiles`)
- `CARGO_HOME` - Custom cargo home directory (`$HOME/.config/cargo`)
- `RUSTUP_HOME` - Custom rustup home directory (`$HOME/.config/rustup`)

## Custom Paths

This feature configures Rust with custom paths to keep the home directory clean:
- **Cargo home:** `~/.config/cargo` (instead of `~/.cargo`)
- **Rustup home:** `~/.config/rustup` (instead of `~/.rustup`)

## Rust Toolchain Management

Includes utilities for:
- Validating rustup and Rust installations
- Getting current Rust version information
- Installing and updating Rust toolchain
- Managing toolchain configurations
- Environment setup and validation

## Migration Status

This feature is being migrated from the old zsh-based scripts to the new bash-based architecture:
- **Old location:** `bin/install/rust.zsh`, `bin/update/rust.zsh`
- **New location:** `features/rust/`
- **Migration benefits:**
  - Self-contained feature with no external dependencies
  - Consistent bash-based implementation
  - Comprehensive utility functions
  - Better error handling and validation
  - Improved testability

## Usage

### Installation
```bash
./features/rust/install.bash
```

### Update
```bash
./features/rust/update.bash
```

### Sourcing utilities
```bash
source "$DOTFILES/features/rust/utils.bash"
validate_rust_installation
get_current_rust_version
```