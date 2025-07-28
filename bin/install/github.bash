#!/usr/bin/env bash

# GitHub SSH setup and repository configuration
# Handles adding SSH keys to GitHub and converting HTTPS remotes to SSH

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"
PRIVATE_KEY="$HOME/.ssh/id_rsa"
PUBLIC_KEY="$PRIVATE_KEY.pub"

# Load utilities
source "$DOTFILES/features/git/utils.bash"

# All needed utilities are now available in github-utils.bash

main() {
    echo "🔑 Adding SSH key pair to GitHub"
    
    # Check if GitHub SSH connection already works
    if github_ssh_connection_works; then
        echo "✅ You can already connect to GitHub via SSH."
        return 0
    fi
    
    # Verify SSH keys exist
    if ! ssh_keys_exist; then
        echo "❌ SSH keys not found. Please run the SSH installation script first."
        echo "Run: source $DOTFILES/bin/install/ssh.zsh"
        return 1
    fi
    
    # Verify SSH keys are loaded in agent
    if ! ssh_keys_in_agent; then
        echo "❌ SSH keys not loaded in ssh-agent. Please add them first."
        echo "Run: ssh-add $PRIVATE_KEY"
        return 1
    fi
    
    # Display public key for user to add to GitHub
    echo ""
    echo "Your turn!"
    echo "Please visit https://github.com/settings/ssh/new now and add the following SSH key to your GitHub account:"
    echo ""
    cat "$PUBLIC_KEY"
    echo ""
    echo "Actually go do this! This step is required before you'll be able to clone repos via SSH."
    echo ""
    
    # Wait for user confirmation (interactive step)
    echo -n "All set? (y/N): "
    read -r github_key_added
    
    if [[ "$github_key_added" != "y" && "$github_key_added" != "Y" ]]; then
        echo "You have chosen...poorly."
        return 0
    else
        echo "Excellent!"
    fi
    
    # Verify GitHub SSH connection now works
    echo ""
    echo "🧪 Verifying you can now connect to GitHub via SSH..."
    
    if github_ssh_connection_works; then
        echo "✅ SSH key was added to GitHub successfully."
    else
        echo "❌ Failed to connect to GitHub via SSH. Please verify the key was added correctly."
        echo "Visit: https://github.com/settings/keys"
        return 1
    fi
    
    # Convert dotfiles remote from HTTPS to SSH if needed
    convert_dotfiles_remote_to_ssh
    
    echo ""
    echo "🚀 Done adding your SSH key pair to GitHub."
}

convert_dotfiles_remote_to_ssh() {
    local dotfiles_dir="$DOTFILES"
    
    # Check if dotfiles directory exists
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "⚠️  Dotfiles directory not found at $dotfiles_dir"
        return 0
    fi
    
    # Get current remote URL
    local current_url
    if ! current_url=$(get_git_remote_url "$dotfiles_dir"); then
        echo "⚠️  Could not get git remote URL for dotfiles"
        return 0
    fi
    
    # Check if remote uses HTTPS
    if is_https_remote "$current_url"; then
        echo ""
        echo "🔗 Converting the dotfiles remote URL from HTTPS to SSH"
        
        local ssh_url
        ssh_url=$(convert_https_to_ssh "$current_url")
        
        if set_git_remote_url "$dotfiles_dir" "$ssh_url"; then
            echo "✅ Dotfiles remote URL has been updated to use SSH"
        else
            echo "❌ Failed to update dotfiles remote URL"
            return 1
        fi
    else
        echo "✅ Dotfiles remote URL already uses SSH"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi