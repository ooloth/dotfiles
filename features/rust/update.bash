#!/usr/bin/env bash

# Rust update script
# Updates Rust toolchain via rustup and validates the installation
#
# This script:
# 1. Checks if rustup is available
# 2. Installs Rust if missing
# 3. Updates the Rust toolchain
# 4. Validates the updated installation

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=features/rust/utils.bash
source "$DOTFILES/features/rust/utils.bash"

main() {
    echo "🦀 Updating Rust..."
    echo ""
    
    # Set up custom environment paths
    setup_rust_environment
    
    # Check if rustup is available
    if ! command_exists rustup; then
        echo "❌ rustup is not installed."
        echo "   Installing Rust first..."
        echo ""
        
        # Install Rust if missing
        if install_rust; then
            echo "✅ Rust installation completed"
        else
            echo "❌ Failed to install Rust"
            return 1
        fi
        
        echo ""
        echo "🎉 Rust installation and update completed"
        return 0
    fi
    
    # Validate rustup installation
    if ! validate_rustup_installation; then
        echo "❌ rustup installation is not functional"
        return 1
    fi
    
    # Display current state before update
    echo "🔍 Current Rust state:"
    local current_version
    if current_version=$(get_current_rust_version); then
        echo "📦 Current Rust version: $current_version"
    else
        echo "⚠️  Could not determine current Rust version"
    fi
    
    local default_toolchain
    if default_toolchain=$(get_default_rust_toolchain); then
        echo "🔧 Default toolchain: $default_toolchain"
    fi
    
    echo ""
    
    # Update Rust toolchain
    echo "🚀 Updating Rust toolchain..."
    if update_rust; then
        echo "✅ Rust toolchain update completed"
    else
        echo "❌ Failed to update Rust toolchain"
        return 1
    fi
    
    echo ""
    
    # Validate the updated installation
    echo "🔍 Validating updated Rust installation..."
    if validate_rust_installation; then
        echo "✅ Rust installation validation passed"
        
        # Display updated version
        local updated_version
        if updated_version=$(get_current_rust_version); then
            echo "📦 Updated Rust version: $updated_version"
        fi
        
        # Display toolchains
        echo ""
        echo "📋 Installed toolchains:"
        if list_rust_toolchains; then
            echo ""
        fi
        
    else
        echo "❌ Rust installation validation failed"
        return 1
    fi
    
    echo "🎉 Rust update completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi