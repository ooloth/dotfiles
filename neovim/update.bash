#!/usr/bin/env bash

# Neovim update script
# Updates Neovim language servers, linters, formatters, and plugins
#
# This script:
# 1. Checks if Neovim and config are installed
# 2. Installs/updates all language servers and tools
# 3. Restores plugin versions from lazy-lock.json
# 4. Validates the updated installation

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=neovim/utils.bash
source "$DOTFILES/neovim/utils.bash"

main() {
    echo "🧃 Updating Neovim configuration and dependencies..."
    echo ""
    
    # Check if Neovim is installed
    if ! is_neovim_installed; then
        echo "❌ Neovim is not installed."
        echo "   Please install Neovim first (e.g., via Homebrew: brew install neovim)"
        echo "   Then run the install script: ./neovim/install.bash"
        echo ""
        return 1
    fi
    
    # Display current Neovim version
    local neovim_version
    if neovim_version=$(get_neovim_version); then
        echo "📦 Current Neovim: $neovim_version"
    fi
    
    echo ""
    
    # Check if config is installed
    if ! is_neovim_config_installed; then
        echo "❌ Neovim config repository is not installed."
        echo "   Installing configuration first..."
        echo ""
        
        # Install the configuration
        if clone_neovim_config; then
            echo "✅ Neovim config repository installed successfully"
        else
            echo "❌ Failed to install Neovim config repository"
            return 1
        fi
        
        echo ""
    else
        echo "✅ Neovim config repository is installed"
        
        # Validate the existing installation
        if validate_neovim_config; then
            echo "✅ Neovim config repository is valid"
        else
            echo "⚠️  Neovim config repository validation failed"
            echo "   Continuing with update, but you may need to reinstall"
        fi
    fi
    
    echo ""
    
    # Update language servers and tools
    echo "🔧 Installing/updating language servers and development tools..."
    echo ""
    
    if install_neovim_language_servers; then
        echo ""
        echo "✅ Language servers and tools update completed"
    else
        echo ""
        echo "⚠️  Some language servers or tools failed to install/update"
        echo "   Continuing with plugin update..."
    fi
    
    echo ""
    
    # Update plugins
    echo "📦 Updating Neovim plugins..."
    if restore_neovim_plugins; then
        echo "✅ Neovim plugins updated successfully"
    else
        echo "❌ Failed to update Neovim plugins"
        return 1
    fi
    
    echo ""
    
    # Final validation
    echo "🔍 Validating updated Neovim installation..."
    if validate_neovim_installation; then
        echo "✅ Neovim installation validation passed"
    else
        echo "⚠️  Some validation checks failed, but update completed"
    fi
    
    echo ""
    echo "🎉 Neovim update completed successfully"
    echo ""
    echo "Summary of updates:"
    echo "  - Language servers and development tools"
    echo "  - Neovim plugins restored from lazy-lock.json"
    echo "  - Configuration validated"
    echo ""
    echo "Next steps:"
    echo "  - Try opening Neovim: nvim"
    echo "  - Language servers should work automatically"
    echo "  - Run :checkhealth in Neovim to verify everything is working"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
