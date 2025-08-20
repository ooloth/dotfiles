# Neovim Feature

This module handles Neovim configuration installation and management for the dotfiles setup.

## Structure

```
neovim/
├── install.bash       # Main installation script
├── update.bash        # Update script for language servers and plugins
├── utils.bash         # Utility functions for Neovim operations
├── config/            # Configuration files and examples
│   ├── init.lua       # Main nvim-ide configuration (Lazy.nvim setup)
│   ├── lazy-lock.json # Plugin lockfile for reproducible builds
│   ├── simple-init.lua # Simple Neovim configuration alternative
│   └── nvim-README.md # Documentation from config/nvim
├── tests/             # Feature tests
│   ├── test-neovim-utils.bats
│   └── test-neovim-installation.bats
└── README.md          # This file
```

## Installation

The installation script:

1. Checks if Neovim is installed (assumes installed via Homebrew)
2. Checks if config.nvim repository is already installed
3. Clones the configuration repository if not present
4. Restores plugin versions from lazy-lock.json using Lazy.nvim

**Prerequisites:**

- Neovim must be installed first (e.g., `brew install neovim`)
- Git with SSH access to GitHub for cloning the config repository

## Update

The update script:

1. Checks if Neovim and config are installed
2. Installs/updates all language servers and development tools
3. Restores plugin versions from lazy-lock.json
4. Validates the updated installation

## Configuration

The script uses these environment variables:

- `DOTFILES` - Path to dotfiles directory (default: `$HOME/Repos/ooloth/dotfiles`)

### Neovim Configurations

This feature includes two Neovim configurations:

1. **Main Configuration (nvim-ide):**
   - Uses `NVIM_APPNAME=nvim-ide` for isolation
   - Loads configuration from `~/Repos/ooloth/config.nvim`
   - Full-featured IDE setup with Lazy.nvim plugin manager
   - Configured for development with language servers

2. **Simple Configuration:**
   - Basic Neovim setup with minimal configuration
   - Found in `config/simple-init.lua`
   - Lightweight alternative for quick editing

### External Repository

The main configuration loads from an external repository:

- **Repository:** `ooloth/config.nvim`
- **Location:** `~/Repos/ooloth/config.nvim`
- **Plugin Manager:** Lazy.nvim
- **Isolation:** Uses `NVIM_APPNAME=nvim-ide`

## Language Server Support

The update script installs language servers and tools for:

- **Astro:** `@astrojs/language-server`
- **Bash:** `shellcheck`, `shfmt`, `bash-language-server`
- **CSS:** `vscode-langservers-extracted`, `css-variables-language-server`, `cssmodules-language-server`, `@tailwindcss/language-server`
- **HTML/XML:** `tidy-html5`, `prettier`
- **JSON:** Included with `vscode-langservers-extracted`
- **Lua:** `lua-language-server`, `stylua`
- **Markdown/MDX:** `marksman`, `@mdx-js/language-service`
- **Python:** `basedpyright`, `ruff`
- **Terraform:** `terraform`, `terraform-ls`, `tflint`
- **TOML:** `taplo-cli`
- **TypeScript/JavaScript:** `typescript`, `typescript-language-server`, `vscode-langservers-extracted`
- **Vue:** `vls`
- **YAML:** `yaml-language-server`

### Package Managers Used

- **npm:** For JavaScript/TypeScript ecosystem tools
- **Homebrew:** For system utilities and some language servers
- **Cargo:** For Rust-based tools (taplo-cli)

## Migration Status

This feature is migrated from the old zsh-based scripts to the new bash-based architecture:

- **Old location:** `bin/install/neovim.zsh`, `bin/update/neovim.zsh`
- **New location:** `neovim/`
- **Migration benefits:**
  - Self-contained feature with no external dependencies
  - Consistent bash-based implementation
  - Comprehensive utility functions
  - Better error handling and validation
  - Improved testability
  - Language server management included

### Key Changes

1. **Converted from Zsh to Bash:** All scripts now use bash for consistency
2. **Enhanced Error Handling:** Better validation and error reporting
3. **Comprehensive Testing:** Full test coverage with BATS framework
4. **Language Server Management:** Automatic installation/update of development tools
5. **Better Isolation:** Clear separation of concerns and no external lib dependencies
6. **Improved Documentation:** Comprehensive README and inline documentation

## Usage

### Installation

```bash
./neovim/install.bash
```

### Update

```bash
./neovim/update.bash
```

### Sourcing utilities

```bash
source "$DOTFILES/neovim/utils.bash"
validate_neovim_installation
get_neovim_version
install_neovim_language_servers
```

## Testing

Run the test suite:

```bash
# Run all neovim tests
bats neovim/tests/

# Run specific test file
bats neovim/tests/test-neovim-utils.bats
bats neovim/tests/test-neovim-installation.bats
```

## Troubleshooting

### Common Issues

1. **Neovim not found:**
   - Install Neovim: `brew install neovim`
   - Verify installation: `nvim --version`

2. **Config repository clone fails:**
   - Ensure SSH access to GitHub is configured
   - Check network connectivity
   - Verify repository exists: `ooloth/config.nvim`

3. **Plugin restoration fails:**
   - Check Neovim can run headlessly: `nvim --headless +q`
   - Verify lazy-lock.json exists in config directory
   - Check network connectivity for plugin downloads

4. **Language server issues:**
   - Run `:checkhealth` in Neovim to diagnose problems
   - Ensure package managers (npm, brew, cargo) are available
   - Check PATH includes language server binaries

### Validation

Use the validation function to check installation health:

```bash
source neovim/utils.bash
validate_neovim_installation
```

This will check:

- Neovim installation and version
- Config repository presence and validity
- Basic functionality tests

