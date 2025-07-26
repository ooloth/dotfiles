#!/usr/bin/env bash

# Node.js installation script (bash version)
# Installs latest Node.js version via fnm

set -euo pipefail

# Load Node.js utilities
source "${DOTFILES:-$HOME/Repos/ooloth/dotfiles}/lib/node-utils.bash"

main() {
    echo "🦀 Installing Node via fnm"
    
    # Check if fnm is installed
    if ! fnm_installed; then
        echo "Error: fnm is not installed. Please install fnm first."
        exit 1
    fi
    
    # Get latest version
    local latest_version
    latest_version=$(get_latest_node_version)
    
    # Check if latest version is already installed
    if check_node_version_installed "$latest_version"; then
        echo "✅ The latest Node version ($latest_version) is already installed."
        return 0
    fi
    
    # Install latest version
    install_node_version "$latest_version"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi