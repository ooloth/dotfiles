#!/usr/bin/env bash

# Content installation script
# Handles cloning and management of the content repository

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/content/utils.bash"
source "$DOTFILES/@common/errors/handling.bash"

main() {
    echo "📂 Installing content repository"
    echo ""

    # Check if content repository is already installed
    if is_content_repo_installed; then
        echo "✅ Content repository is already installed"
        return 0
    fi

    # Install content repository
    if ! install_content_repo; then
        echo "❌ Failed to install content repository"
        exit 1
    fi

    echo ""
    echo "🎉 Content repository installation complete!"
}

# Run main function
main "$@"

