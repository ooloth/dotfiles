# Node.js Feature

Self-contained Node.js installation and management feature using fnm (Fast Node Manager).

## Overview

This feature provides automated installation and management of Node.js via fnm, including:

- ✅ Latest Node.js version installation via fnm
- ✅ Automatic version detection and updates
- ✅ Global npm package management
- ✅ Neovim language server integration
- ✅ Corepack support for package manager compatibility

## Files

```
features/node/
├── install.bash        # Node.js installation via fnm
├── update.bash         # Node.js and npm package updates
├── utils.bash          # Node.js utility functions
├── config/             # Node.js configuration files (empty - no configs needed)
├── tests/              # Comprehensive test suite
│   ├── test-node-utils.bats
│   ├── test-node-installation.bats
│   └── test-node-update.bats
└── README.md           # This documentation
```

## Prerequisites

- **fnm (Fast Node Manager)**: Must be installed and available in PATH
- **Shell environment**: fnm must be configured in your shell (usually via `eval "$(fnm env)"`)

### Installing fnm

```bash
# Install fnm (Fast Node Manager)
curl -fsSL https://fnm.vercel.app/install | bash

# Add to your shell configuration
eval "$(fnm env --use-on-cd)"
```

## Usage

### Installation

```bash
# Install latest Node.js version
./features/node/install.bash
```

### Updates

```bash
# Update Node.js and global npm packages
./features/node/update.bash
```

## What Gets Installed

### Node.js
- Latest stable Node.js version via fnm
- Corepack enabled for package manager compatibility
- Version set as default and activated

### Global npm Packages

**General Development Tools:**
- `@anthropic-ai/claude-code` - Claude Code CLI
- `npm` - npm package manager (updated to latest)
- `npm-check` - Check for outdated packages
- `trash-cli` - Safe file deletion

**Neovim Language Servers:**
- `bash-language-server` - Bash language support
- `cssmodules-language-server` - CSS modules support
- `dockerfile-language-server-nodejs` - Dockerfile support
- `emmet-ls` - Emmet language server
- `neovim` - Neovim npm package
- `pug-lint` - Pug template linting
- `svelte-language-server` - Svelte support
- `tree-sitter-cli` - Tree-sitter CLI
- `typescript` - TypeScript compiler
- `vscode-langservers-extracted` - VS Code language servers

## Features

### Smart Version Management
- Detects if latest Node.js version is already installed
- Only installs/updates when necessary
- Preserves existing installations while adding new versions

### Comprehensive Package Management
- Automatically installs missing global packages
- Updates outdated packages
- Maintains consistent development environment

### Error Handling
- Validates fnm installation before proceeding
- Provides clear error messages and troubleshooting guidance
- Graceful handling of network issues and installation failures

### Integration
- Works with existing fnm configurations
- Compatible with shell auto-switching (`.node-version` files)
- Supports both development and production workflows

## Testing

The feature includes comprehensive tests covering:

- **Utility Functions** (`test-node-utils.bats`): Unit tests for all utility functions
- **Installation** (`test-node-installation.bats`): Integration tests for installation workflow
- **Updates** (`test-node-update.bats`): Tests for update and package management

```bash
# Run all Node.js tests
bats features/node/tests/

# Run specific test file
bats features/node/tests/test-node-utils.bats
```

## Configuration

This feature is designed to be self-contained and requires no additional configuration files. It works with:

- **fnm's default configuration** (`~/.fnm/`)
- **npm's global configuration** (`~/.npm-global/` or system default)
- **Shell integration** via fnm environment setup

## Integration with Dotfiles

### Shell Integration

The feature works with existing shell configurations that include:

```bash
# In your shell config (e.g., ~/.zshrc)
eval "$(fnm env --use-on-cd --log-level=error)"
```

### Aliases

Common aliases that work with this feature:

```bash
alias n="npm install"
alias ng="./features/node/update.bash"  # Update Node.js and npm
alias nvm="fnm"  # fnm as nvm replacement
```

## Troubleshooting

### fnm Not Found
```
❌ fnm (Fast Node Manager) is not installed.
   Please install fnm first: https://github.com/Schniz/fnm
```

**Solution:** Install fnm and ensure it's in your PATH.

### fnm Not Functional
```
❌ fnm installation is not functional
```

**Solution:** Check that fnm is properly configured in your shell environment.

### Network Issues
```
❌ Failed to determine latest Node.js version
```

**Solution:** Check internet connection and fnm's ability to fetch remote versions.

### Permission Issues
```
❌ Failed to install Node.js version
```

**Solution:** Ensure fnm has proper permissions to install Node.js versions.

## Migration from Legacy Scripts

This feature replaces:
- `bin/install/node.zsh` - Now `features/node/install.bash`
- `bin/update/npm.zsh` - Now `features/node/update.bash`

### Key Improvements

1. **Self-contained**: No dependencies on external library files
2. **Better error handling**: More robust error detection and reporting
3. **Comprehensive testing**: Full test coverage for all functionality
4. **Bash compatibility**: Works in both bash and zsh environments
5. **Modular design**: Clear separation of concerns between installation and updates

## Related Features

- **Homebrew** (`features/homebrew/`): May install fnm if configured
- **Shell** configurations: Integrate with fnm environment setup
- **Neovim** configurations: Use installed language servers