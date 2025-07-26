#!/usr/bin/env bash
# Utilities for managing content repository installation

set -euo pipefail

# Check if content repository is already cloned
is_content_repo_installed() {
  local repo_path="${1:-$HOME/Repos/ooloth/content}"
  [[ -d "$repo_path" ]]
}

# Clone content repository
clone_content_repo() {
  local repo_url="${1:-git@github.com:ooloth/content.git}"
  local repo_path="${2:-$HOME/Repos/ooloth/content}"
  
  echo "📂 Installing content repo"
  
  # Create parent directory
  mkdir -p "$(dirname "$repo_path")"
  
  # Clone the repository
  if ! git clone "$repo_url" "$repo_path"; then
    echo "❌ Failed to clone content repository"
    return 1
  fi
}

# Get content repository path
get_content_repo_path() {
  echo "$HOME/Repos/ooloth/content"
}

# Check if git is available
is_git_available() {
  command -v git >/dev/null 2>&1
}

# Validate repository URL format
is_valid_repo_url() {
  local url="$1"
  # Check for basic git URL patterns
  [[ "$url" =~ ^(git@|https://) ]] && [[ "$url" =~ \.(git|com|org)(/|$) ]]
}

# Check if repository directory is a valid git repository
is_valid_git_repo() {
  local repo_path="$1"
  [[ -d "$repo_path/.git" ]] || git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1
}