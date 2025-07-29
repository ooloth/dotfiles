#!/usr/bin/env bash

# Content utilities
# Helper functions for content repository management

set -euo pipefail

# Configuration
readonly CONTENT_REPO="ooloth/content"
readonly CONTENT_LOCAL_PATH="$HOME/Repos/$CONTENT_REPO"

# Check if content repository is already installed
is_content_repo_installed() {
    if [[ -d "$CONTENT_LOCAL_PATH" ]]; then
        echo "📂 Content repository is already installed at: $CONTENT_LOCAL_PATH"
        return 0
    fi
    return 1
}

# Install content repository
install_content_repo() {
    echo "🔄 Cloning content repository..."
    
    # Create parent directory if it doesn't exist
    local parent_dir
    parent_dir="$(dirname "$CONTENT_LOCAL_PATH")"
    
    if ! mkdir -p "$parent_dir"; then
        echo "❌ Failed to create parent directory: $parent_dir"
        return 1
    fi
    
    # Clone the repository
    if ! git clone "git@github.com:$CONTENT_REPO.git" "$CONTENT_LOCAL_PATH"; then
        echo "❌ Failed to clone content repository"
        return 1
    fi
    
    echo "✅ Content repository cloned successfully to: $CONTENT_LOCAL_PATH"
    return 0
}