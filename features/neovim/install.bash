#!/usr/bin/env bash

# Neovim installation script
# Installs Neovim configuration repository and restores plugins
#
# This script:
# 1. Checks if Neovim is installed (assumes installed via Homebrew)
# 2. Checks if config.nvim repository is already installed
# 3. Clones the configuration repository if not present
# 4. Restores plugin versions from lazy-lock.json

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=features/neovim/utils.bash
source "$DOTFILES/features/neovim/utils.bash"

main() {
    echo "📂 Installing Neovim configuration..."
    echo ""
    
    # Check if Neovim is installed
    if ! is_neovim_installed; then
        echo "❌ Neovim is not installed."
        echo "   Please install Neovim first (e.g., via Homebrew: brew install neovim)"
        echo ""
        return 1
    fi
    
    # Display Neovim version
    local neovim_version
    if neovim_version=$(get_neovim_version); then
        echo "📦 Found Neovim: $neovim_version"
    fi
    
    echo ""
    
    # Check if config is already installed
    if is_neovim_config_installed; then
        echo "✅ config.nvim is already installed"
        
        # Validate the existing installation
        if validate_neovim_config; then
            echo "✅ Neovim config repository is valid"
        else
            echo "⚠️  Neovim config repository validation failed"
            echo "   You may need to reinstall the configuration"
            return 1
        fi
        
        echo ""
        
        # Still restore plugins to ensure they're up to date
        echo "🔄 Ensuring plugins are up to date..."
        if restore_neovim_plugins; then
            echo "✅ Plugin restoration completed"
        else
            echo "⚠️  Plugin restoration failed, but config is installed"
        fi
        
        echo ""
        echo "📂 Neovim setup completed"
        return 0
    fi
    
    echo "📂 config.nvim not found, proceeding with installation..."
    echo ""
    
    # Clone the Neovim configuration repository
    if clone_neovim_config; then
        echo "✅ config.nvim repository installed successfully"
    else
        echo "❌ Failed to install config.nvim repository"
        return 1
    fi
    
    echo ""
    
    # Validate the installation
    echo "🔍 Validating Neovim configuration..."
    if validate_neovim_config; then
        echo "✅ Neovim config repository validation passed"
    else
        echo "❌ Neovim config repository validation failed"
        return 1
    fi
    
    echo ""
    
    # Restore plugins from lockfile
    echo "📦 Installing Neovim plugins..."
    if restore_neovim_plugins; then
        echo "✅ Neovim plugins installed successfully"
    else
        echo "❌ Failed to install Neovim plugins"
        echo "   The configuration is installed but plugins may not be working"
        return 1
    fi
    
    echo ""
    
    # Final validation
    echo "🔍 Final validation..."
    if validate_neovim_installation; then
        echo "✅ Complete Neovim installation validation passed"
    else
        echo "⚠️  Some validation checks failed"
    fi
    
    echo ""
    echo "🚀 Finished installing Neovim configuration successfully"
    echo ""
    echo "Next steps:"
    echo "  - Try opening Neovim: nvim"
    echo "  - The configuration uses NVIM_APPNAME=nvim-ide for isolation"
    echo "  - Plugins are managed by Lazy.nvim and should load automatically"
    echo "  - See the config.nvim repository for usage details"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi