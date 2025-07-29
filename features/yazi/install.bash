#!/usr/bin/env bash

# Yazi installation script
# Handles Yazi file manager flavors installation with machine detection

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils.bash"
source "$DOTFILES/core/detection/machine.bash"
source "$DOTFILES/core/errors/handling.bash"

main() {
    echo "📁 Setting up Yazi file manager flavors"
    echo ""
    
    # Initialize machine detection
    init_machine_detection
    
    # Skip installation on work machines
    if [[ "${IS_WORK:-false}" == "true" ]]; then
        echo "⏭️  Skipping yazi flavors installation on work machine"
        return 0
    fi
    
    echo "📅 Machine type: $MACHINE (proceeding with installation)"
    echo ""
    
    # Check if flavors are already installed
    if is_yazi_flavors_installed; then
        echo "✅ Yazi flavors are already installed"
    else
        # Install yazi flavors
        if ! install_yazi_flavors; then
            echo "❌ Failed to install yazi flavors"
            exit 1
        fi
    fi
    
    # Setup theme symlink
    echo ""
    if ! setup_yazi_theme; then
        echo "❌ Failed to setup yazi theme"
        exit 1
    fi
    
    echo ""
    echo "🎉 Yazi setup complete!"
}

# Run main function
main "$@"