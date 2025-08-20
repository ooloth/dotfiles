#!/usr/bin/env bash

# Rust installation script
# Installs and configures Rust via rustup with custom paths
#
# This script:
# 1. Checks if rustup is already installed
# 2. Sets up custom CARGO_HOME and RUSTUP_HOME paths  
# 3. Downloads and installs rustup if not present
# 4. Validates the installation

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=rust/utils.bash
source "$DOTFILES/rust/utils.bash"

main() {
    echo "🦀 Installing Rust..."
    echo ""
    
    # Set up custom environment paths
    setup_rust_environment
    
    # Check if Rust is already installed
    if is_rust_installed; then
        echo "✅ Rust is already installed"
        
        # Display current version
        local current_version
        if current_version=$(get_current_rust_version); then
            echo "📦 Current Rust version: $current_version"
        fi
        
        # Validate installation
        if validate_rust_installation; then
            echo "✅ Rust installation is functional"
        else
            echo "⚠️  Rust installation validation failed"
        fi
        
        echo ""
        echo "🦀 Rust setup completed"
        return 0
    fi
    
    echo "📦 Rust not found, proceeding with installation..."
    
    # Install Rust
    if install_rust; then
        echo "✅ Rust installation completed"
    else
        echo "❌ Failed to install Rust"
        return 1
    fi
    
    echo ""
    
    # Validate the installation
    echo "🔍 Validating Rust installation..."
    if validate_rust_installation; then
        echo "✅ Rust installation validation passed"
        
        # Display installed version
        local installed_version
        if installed_version=$(get_current_rust_version); then
            echo "📦 Installed Rust version: $installed_version"
        fi
        
        # Display default toolchain
        local default_toolchain
        if default_toolchain=$(get_default_rust_toolchain); then
            echo "🔧 Default toolchain: $default_toolchain"
        fi
        
    else
        echo "❌ Rust installation validation failed"
        return 1
    fi
    
    echo ""
    echo "🚀 Finished installing Rust successfully"
    echo ""
    echo "Next steps:"
    echo "  - Restart your shell or run: source ~/.config/cargo/env"
    echo "  - Try: cargo --version"
    echo "  - Try: rustc --version"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
