#!/usr/bin/env bash

# Yazi update script
# Updates Yazi file manager flavors with machine detection

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils.bash"
source "$DOTFILES/core/detection/machine.bash"
source "$DOTFILES/core/errors/handling.bash"

main() {
    echo "📁 Updating Yazi file manager flavors"
    echo ""
    
    # Initialize machine detection
    init_machine_detection
    
    # Skip update on work machines
    if [[ "${IS_WORK:-false}" == "true" ]]; then
        echo "⏭️  Skipping yazi flavors update on work machine"
        return 0
    fi
    
    echo "📅 Machine type: $MACHINE (proceeding with update)"
    echo ""
    
    # Check if flavors are installed
    if ! is_yazi_flavors_installed; then
        echo "📦 Yazi flavors not installed, running installation..."
        if ! "$SCRIPT_DIR/install.bash"; then
            echo "❌ Failed to install yazi flavors"
            exit 1
        fi
        return 0
    fi
    
    # Update yazi flavors
    if ! update_yazi_flavors; then
        echo "❌ Failed to update yazi flavors"
        exit 1
    fi
    
    echo ""
    echo "🎉 Yazi flavors update complete!"
}

# Run main function
main "$@"