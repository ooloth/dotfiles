#!/usr/bin/env bash

# GitHub utilities for dotfiles setup

set -euo pipefail

# Check if we can connect to GitHub via SSH
can_connect_to_github_via_ssh() {
    ssh -T git@github.com &>/dev/null
    local exit_code=$?
    # GitHub returns exit code 1 on successful authentication
    # See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection
    [[ $exit_code -eq 1 ]]
}

# Check if GitHub CLI is installed
is_github_cli_installed() {
    command -v gh >/dev/null 2>&1
}

# Get the current remote URL for a git repository
get_git_remote_url() {
    local remote="${1:-origin}"
    git config --get "remote.${remote}.url" 2>/dev/null || echo ""
}

# Convert HTTPS URL to SSH URL for GitHub
convert_github_https_to_ssh() {
    local https_url="$1"
    if [[ "$https_url" =~ ^https://github\.com/(.+)$ ]]; then
        echo "git@github.com:${BASH_REMATCH[1]}"
    else
        echo "$https_url"
    fi
}

# Check if a remote URL is using HTTPS
is_https_url() {
    local url="$1"
    [[ "$url" =~ ^https:// ]]
}

# Set git remote URL
set_git_remote_url() {
    local remote="${1:-origin}"
    local url="$2"
    git remote set-url "$remote" "$url"
}

# Display SSH public key
display_ssh_public_key() {
    local public_key="$HOME/.ssh/id_rsa.pub"
    if [[ -f "$public_key" ]]; then
        cat "$public_key"
        return 0
    else
        echo "Error: SSH public key not found at $public_key" >&2
        return 1
    fi
}

# Install GitHub CLI using Homebrew
install_github_cli() {
    if command -v brew >/dev/null 2>&1; then
        echo "📦 Installing GitHub CLI..."
        if brew install gh; then
            echo "✅ GitHub CLI installed successfully"
            return 0
        else
            echo "❌ Failed to install GitHub CLI" >&2
            return 1
        fi
    else
        echo "❌ Homebrew not found. Please install Homebrew first." >&2
        return 1
    fi
}