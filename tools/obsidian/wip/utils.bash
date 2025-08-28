#!/usr/bin/env bash

# Content utilities for dotfiles setup

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
    echo "📦 Cloning content repository..."
    
    # Create parent directory
    local parent_dir="$(dirname "$CONTENT_LOCAL_PATH")"
    mkdir -p "$parent_dir"
    
    # Try SSH first, fallback to HTTPS
    if ! timeout 30 git clone "git@github.com:$CONTENT_REPO.git" "$CONTENT_LOCAL_PATH" 2>/dev/null; then
        echo "SSH clone failed, trying HTTPS..."
        if ! timeout 30 git clone "https://github.com/$CONTENT_REPO.git" "$CONTENT_LOCAL_PATH"; then
            echo "❌ Failed to clone content repository" >&2
            return 1
        fi
    fi
    
    echo "✅ Content repository cloned successfully"
    return 0
}
