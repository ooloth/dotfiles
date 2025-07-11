#!/usr/bin/env bash

# Rust installation script (bash version)
# Installs Rust toolchain using rustup if not already installed

# shellcheck disable=SC1091  # Don't follow sourced files

set -euo pipefail

# Load Rust utilities
source "${DOTFILES:-$HOME/Repos/ooloth/dotfiles}/lib/rust-utils.bash"

main() {
    # Check if Rust is already installed
    if rust_installed; then
        echo "🦀 Rust is already installed"
        return 0
    fi
    
    # Set up environment variables
    setup_rust_environment
    
    # Install Rust toolchain
    install_rust_toolchain
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi