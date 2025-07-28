# Zsh Feature

This feature provides automated installation, configuration, and management of Zsh shell with Homebrew integration.

## Overview

The Zsh feature handles:

- **Installation**: Installs Zsh via Homebrew if not present
- **Shell Configuration**: Adds Zsh to `/etc/shells` and sets as default shell  
- **Configuration Management**: Manages comprehensive Zsh configuration files
- **Updates**: Updates Zsh via Homebrew and validates configuration
- **Validation**: Ensures proper installation and configuration

## Files

### Core Scripts

- **`install.bash`** - Main installation script that sets up Zsh as default shell
- **`update.bash`** - Updates Zsh via Homebrew and re-validates configuration  
- **`utils.bash`** - Utility functions for Zsh installation and management

### Configuration

- **`config/`** - Zsh configuration files including:
  - `aliases.zsh` - Shell aliases and shortcuts
  - `options.zsh` - Zsh options and behavior settings
  - `path.zsh` - PATH and environment variable configuration
  - `plugins.zsh` - Plugin management and configuration
  - `utils.zsh` - Utility functions and helper scripts
  - `variables.zsh` - Environment variable definitions
  - `work/` - Work-specific configuration overrides

### Tests

- **`tests/test-zsh-utils.bats`** - Unit tests for utility functions
- **`tests/test-zsh-installation.bats`** - Integration tests for installation workflow
- **`tests/test-zsh-update.bats`** - Tests for update functionality

## Usage

### Installation

```bash
# Install and configure Zsh as default shell
./features/zsh/install.bash
```

The installation script will:

1. Check if Zsh is already installed at `/opt/homebrew/bin/zsh`
2. Install Zsh via Homebrew if not present (requires Homebrew)
3. Add Zsh to `/etc/shells` if not already listed
4. Change user's default shell to Zsh
5. Validate the installation and configuration

### Updates

```bash
# Update Zsh via Homebrew
./features/zsh/update.bash
```

The update script will:

1. Update Zsh via Homebrew
2. Re-validate Zsh is properly listed in `/etc/shells`
3. Verify user shell is still correctly set
4. Validate installation and configuration
5. Show current version and path information

### Testing

```bash
# Run all Zsh feature tests
bats features/zsh/tests/

# Run specific test files
bats features/zsh/tests/test-zsh-utils.bats
bats features/zsh/tests/test-zsh-installation.bats
bats features/zsh/tests/test-zsh-update.bats
```

## Dependencies

### Required

- **Homebrew** - Used to install and update Zsh
- **sudo access** - Required to modify `/etc/shells` and change user shell

### Optional

- **Zsh configuration files** - Located in `config/` directory
- **Work-specific configs** - Applied automatically on work machines

## Configuration

### Environment Variables

- **`DOTFILES`** - Path to dotfiles repository (defaults to `$HOME/Repos/ooloth/dotfiles`)

### Shell Path

The feature uses Homebrew's Zsh installation at `/opt/homebrew/bin/zsh` rather than the system Zsh to ensure a modern, up-to-date version.

### Configuration Files

All Zsh configuration files are organized in the `config/` directory:

- **Core files** - Essential configuration for all environments
- **Work directory** - Work-specific overrides and additions
- **Machine detection** - Configurations applied based on machine type

## Machine Detection

The feature integrates with the dotfiles machine detection system:

- **Personal machines** - Standard configuration
- **Work machines** - Additional work-specific configurations loaded
- **Environment-specific** - Configurations adapted to machine context

## Error Handling

The scripts include comprehensive error handling:

- **Prerequisites** - Validates Homebrew availability before installation
- **Validation** - Confirms proper installation and configuration
- **Graceful failures** - Continues when possible, warns on non-critical issues
- **Rollback safety** - Operations are safe and can be re-run

## Security Considerations

- **Sudo usage** - Minimal and only for system-level changes (`/etc/shells`, `chsh`)
- **Path validation** - Validates shell path before setting
- **File permissions** - Respects existing file permissions and ownership

## Troubleshooting

### Common Issues

1. **Homebrew not installed**
   ```bash
   # Install Homebrew first
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Permission denied when changing shell**
   ```bash
   # Ensure you have sudo access
   sudo -v
   ```

3. **Zsh not found after installation**
   ```bash
   # Check Homebrew installation
   brew list zsh
   ls -la /opt/homebrew/bin/zsh
   ```

4. **Configuration not loading**
   ```bash
   # Verify configuration files exist
   ls -la features/zsh/config/
   echo $DOTFILES
   ```

### Manual Recovery

If automatic installation fails, you can manually:

1. Install Zsh: `brew install zsh`
2. Add to shells: `echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells`
3. Change shell: `sudo chsh -s /opt/homebrew/bin/zsh $USER`

## Integration

This feature integrates with:

- **Homebrew feature** - For Zsh installation and updates
- **Symlink management** - For configuration file deployment
- **Machine detection** - For environment-specific configurations
- **Git workflow** - For version control and change tracking

## Contributing

When modifying this feature:

1. **Run tests** - Ensure all tests pass: `bats features/zsh/tests/`
2. **Update documentation** - Keep README current with changes
3. **Follow patterns** - Maintain consistency with other features
4. **Test thoroughly** - Test on different machine types and scenarios