#!/usr/bin/env bash

# macOS update script
# Handles macOS system software updates with machine detection

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils.bash"
source "$DOTFILES/@common/detection/machine.bash"
source "$DOTFILES/@common/errors/handling.bash"

main() {
    echo "🍎 macOS System Update"
    echo ""

    # Initialize machine detection
    init_machine_detection

    # Skip updates on work machines
    if [[ "${IS_WORK:-false}" == "true" ]]; then
        echo "⏭️  Skipping macOS updates on work machine to avoid disruption"
        echo "   Work machines should be updated through corporate policies"
        return 0
    fi

    echo "📅 Machine type: $MACHINE (proceeding with updates)"
    echo ""

    # Verify we're on macOS
    if ! is_macos; then
        echo "❌ This script only works on macOS"
        exit 1
    fi

    # Run software update
    echo "🔄 Starting macOS software update process..."
    echo "⚠️  After entering your password, please do not cancel the process"
    echo ""

    if ! run_macos_software_update; then
        echo "❌ macOS software update failed"
        exit 1
    fi

    echo ""
    echo "🎉 macOS update process complete!"
    echo "🔄 Your system will restart if updates require it"
}

# Run main function
main "$@"

