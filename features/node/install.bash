#!/usr/bin/env bash

# Node.js installation script
# Installs and configures Node.js via fnm (Fast Node Manager)
#
# This script:
# 1. Checks if fnm (Fast Node Manager) is available
# 2. Installs the latest Node.js version via fnm
# 3. Sets the latest version as default
# 4. Enables corepack for package manager integration

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=features/node/utils.bash
source "$DOTFILES/features/node/utils.bash"

main() {
    echo "🦀 Installing Node.js via fnm..."
    echo ""
    
    # Check if fnm is available
    if ! command -v fnm >/dev/null 2>&1; then
        echo "❌ fnm (Fast Node Manager) is not installed."
        echo "   Please install fnm first: https://github.com/Schniz/fnm"
        return 1
    fi
    
    # Validate fnm installation
    if ! validate_fnm_installation; then
        echo "❌ fnm installation is not functional"
        return 1
    fi
    
    # Get the latest Node.js version
    echo "🔍 Finding latest Node.js version..."
    local latest_version
    if ! latest_version=$(get_latest_node_version); then
        echo "❌ Failed to determine latest Node.js version"
        return 1
    fi
    
    echo "📦 Latest Node.js version: $latest_version"
    
    # Check if latest version is already installed
    if is_node_version_installed "$latest_version"; then
        echo "✅ The latest Node.js version ($latest_version) is already installed"
        
        # Ensure it's set as default
        if set_default_node_version "$latest_version"; then
            echo "✅ Latest version set as default"
        else
            echo "⚠️  Failed to set latest version as default"
        fi
        
        echo ""
        echo "🦀 Node.js setup completed"
        return 0
    fi
    
    # Install the latest version
    echo "📦 Installing Node.js $latest_version..."
    if install_node_version "$latest_version"; then
        echo "✅ Node.js $latest_version installed successfully"
    else
        echo "❌ Failed to install Node.js $latest_version"
        return 1
    fi
    
    # Set as default version
    echo "🔧 Setting Node.js $latest_version as default..."
    if set_default_node_version "$latest_version"; then
        echo "✅ Node.js $latest_version set as default"
    else
        echo "❌ Failed to set Node.js $latest_version as default"
        return 1
    fi
    
    # Activate the new version
    echo "🚀 Activating Node.js $latest_version..."
    if activate_node_version "$latest_version"; then
        echo "✅ Node.js $latest_version activated"
    else
        echo "❌ Failed to activate Node.js $latest_version"
        return 1
    fi
    
    # Validate the installation
    echo "🔍 Validating Node.js installation..."
    if validate_node_installation; then
        echo "✅ Node.js installation validation passed"
    else
        echo "⚠️  Node.js installation validation failed"
    fi
    
    echo ""
    echo "🚀 Finished installing Node.js $latest_version"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi