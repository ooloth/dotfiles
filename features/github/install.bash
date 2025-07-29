#!/usr/bin/env bash

# GitHub installation script
# Handles GitHub CLI installation and SSH key configuration

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils.bash"
source "$DOTFILES/core/errors/handling.bash"

main() {
    echo "🐙 Setting up GitHub"
    echo ""
    
    # Check if GitHub CLI is installed
    if ! is_github_cli_installed; then
        echo "📦 GitHub CLI not found, installing..."
        if ! install_github_cli; then
            echo "❌ Failed to install GitHub CLI"
            exit 1
        fi
    else
        echo "✅ GitHub CLI is already installed"
    fi
    
    # Check SSH connection to GitHub
    echo ""
    echo "🔍 Checking SSH connection to GitHub..."
    
    if can_connect_to_github_via_ssh; then
        echo "✅ You can already connect to GitHub via SSH"
    else
        echo "❌ Cannot connect to GitHub via SSH"
        echo ""
        echo "📋 Please add the following SSH key to your GitHub account:"
        echo "   https://github.com/settings/ssh/new"
        echo ""
        
        if ! display_ssh_public_key; then
            echo "❌ SSH key not found. Please run the SSH installation first."
            exit 1
        fi
        
        echo ""
        echo "Press Enter after you've added the key to GitHub..."
        read -r
        
        echo ""
        echo "🧪 Verifying connection..."
        if can_connect_to_github_via_ssh; then
            echo "✅ SSH connection to GitHub verified!"
        else
            echo "❌ Still cannot connect to GitHub via SSH"
            echo "   Please ensure you've added the key correctly"
            exit 1
        fi
    fi
    
    # Convert dotfiles remote from HTTPS to SSH if needed
    echo ""
    echo "🔗 Checking dotfiles remote URL..."
    
    # Save current directory
    local current_dir
    current_dir=$(pwd)
    
    # Change to dotfiles directory
    cd "$DOTFILES" || exit 1
    
    # Get current remote URL
    local remote_url
    remote_url=$(get_git_remote_url "origin")
    
    if [[ -z "$remote_url" ]]; then
        echo "⚠️  No remote URL found for origin"
    elif is_https_url "$remote_url"; then
        echo "📝 Converting remote URL from HTTPS to SSH..."
        local ssh_url
        ssh_url=$(convert_github_https_to_ssh "$remote_url")
        
        if [[ "$ssh_url" != "$remote_url" ]]; then
            set_git_remote_url "origin" "$ssh_url"
            echo "✅ Remote URL updated: $ssh_url"
        else
            echo "⚠️  Could not convert URL: $remote_url"
        fi
    else
        echo "✅ Remote URL already using SSH: $remote_url"
    fi
    
    # Return to original directory
    cd "$current_dir" || exit 1
    
    echo ""
    echo "🎉 GitHub setup complete!"
}

# Run main function
main "$@"