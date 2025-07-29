# GitHub Feature

This feature manages GitHub CLI installation and SSH key configuration for GitHub access.

## What it does

1. **GitHub CLI Installation**: Installs the GitHub CLI (`gh`) if not present
2. **SSH Key Configuration**: Adds existing SSH keys to GitHub for authentication
3. **Repository Configuration**: Converts dotfiles remote from HTTPS to SSH
4. **Connection Verification**: Tests SSH connectivity to GitHub

## Dependencies

- **Git**: Must be installed (provided by `features/git/`)
- **SSH**: SSH keys must exist (provided by `features/ssh/`)
- **Homebrew**: Used to install GitHub CLI

## Installation

```bash
./features/github/install.bash
```

## Configuration

No configuration files are managed by this feature. It uses:
- SSH keys from `~/.ssh/`
- Git configuration for remote URL management

## Testing

```bash
bats features/github/tests/
```