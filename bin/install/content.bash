#!/usr/bin/env bash
# Install content repository

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES/lib/content-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

# Configuration
REPO_URL="git@github.com:ooloth/content.git"
REPO_PATH="$(get_content_repo_path)"

# Check if already installed
if is_content_repo_installed "$REPO_PATH"; then
  echo ""
  echo "📂 content repo is already installed"
  exit 0
fi

# Validate prerequisites
if ! is_git_available; then
  echo "❌ git is not available. Please install git first."
  exit 1
fi

if ! is_valid_repo_url "$REPO_URL"; then
  echo "❌ Invalid repository URL: $REPO_URL"
  exit 1
fi

# Clone content repository
echo ""
if is_dry_run; then
  echo "[DRY RUN] Would clone content repository to $REPO_PATH"
else
  if ! clone_content_repo "$REPO_URL" "$REPO_PATH"; then
    echo "❌ Failed to install content repository"
    exit 1
  fi
  
  # Verify the clone was successful
  if ! is_valid_git_repo "$REPO_PATH"; then
    echo "❌ Cloned repository is not a valid git repository"
    exit 1
  fi
  
  echo ""
  echo "✅ content repo installed successfully"
fi