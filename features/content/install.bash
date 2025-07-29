#!/usr/bin/env bash

# Content installation script
# Handles cloning the ooloth/content repository for content creation tools
#
# This script:
# 1. Checks if content repository is already cloned
# 2. Clones the repository if not present

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/features/content/utils.bash"
source "$DOTFILES/core/errors/handling.bash"

main() {
    echo "📂 Installing content repository"
    echo ""
    
    # Check if content repo is already installed
    if is_content_repo_installed; then
        echo "✅ Content repository is already installed"
        return 0
    fi
    
    # Clone the repository
    if ! install_content_repo; then
        echo "❌ Failed to install content repository"
        exit 1
    fi
    
    echo ""
    echo "🎉 Content repository installation complete!"
}

# Run main function
main "$@"