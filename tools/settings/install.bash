#!/usr/bin/env bash

# Settings installation script
# Handles macOS system preferences and settings configuration

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "${DOTFILES}/tools/settings/utils.bash"
source "${DOTFILES}/@common/detection/macos.bash"
source "${DOTFILES}/@common/errors/handling.bash"

main() {
    echo "💻 Configuring macOS system settings"
    echo ""

    # Check if we're on macOS
    if ! is_macos; then
        echo "⏭️  Skipping settings configuration (not on macOS)"
        return 0
    fi

    # Configure general settings
    if ! configure_general_settings; then
        echo "❌ Failed to configure general settings"
        exit 1
    fi

    # Configure Finder
    if ! configure_finder_settings; then
        echo "❌ Failed to configure Finder settings"
        exit 1
    fi

    # Configure Safari
    if ! configure_safari_settings; then
        echo "❌ Failed to configure Safari settings"
        exit 1
    fi

    echo ""
    echo "🎉 macOS system settings configuration complete!"
}

# Run main function
main "$@"
