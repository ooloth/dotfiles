#!/usr/bin/env bash

# UV installation script
# Installs UV Python package installer

set -euo pipefail

# Get the dotfiles directory
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/lib/uv-utils.bash"

main() {
    if uv_installed; then
        echo "⚡️ UV is already installed"
        return 0
    fi

    echo "⚡️ Installing UV..."
    
    # Install UV via Homebrew
    install_uv_via_brew
    
    # Show installed version
    echo "🚀 Finished installing $(get_uv_version)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi