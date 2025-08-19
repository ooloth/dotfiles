#!/usr/bin/env bash

# SSH update script
# Updates SSH configuration and validates SSH key setup
#
# This script:
# 1. Validates existing SSH key pair
# 2. Ensures SSH configuration is up-to-date
# 3. Checks SSH agent configuration
# 4. Validates keychain integration (macOS)
# 5. Tests SSH connectivity to common services

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=features/ssh/utils.bash
source "$DOTFILES/features/ssh/utils.bash"

main() {
    echo "🔑 Updating SSH configuration..."
    echo ""
    
    # Check if SSH keys exist
    if ! detect_ssh_keys; then
        echo "❌ SSH keys not found."
        echo "   Please run the install script first to generate SSH keys:"
        echo "   ./features/ssh/install.bash"
        echo ""
        return 1
    fi
    
    # Get SSH paths
    get_ssh_key_paths
    local ssh_config="$SSH_DIR/config"
    
    echo "✅ SSH key pair validated"
    echo "   Private key: $SSH_PRIVATE_KEY"
    echo "   Public key: $SSH_PUBLIC_KEY"
    echo ""
    
    # Check and update SSH config file
    echo "📝 Checking SSH configuration..."
    
    if ssh_config_has_required_settings "$ssh_config"; then
        echo "✅ SSH config file has all required settings"
    else
        echo "⚠️  SSH config file missing required settings, updating..."
        
        # Backup existing config if it exists and is not empty
        if [[ -s "$ssh_config" ]]; then
            local backup_path
            backup_path="${ssh_config}.backup.$(date +%s)"
            echo "📦 Backing up existing SSH config to: $backup_path"
            cp "$ssh_config" "$backup_path"
        fi
        
        # Create/update SSH config
        if create_ssh_config "$ssh_config"; then
            echo "✅ SSH config file updated successfully"
        else
            echo "❌ Failed to update SSH config file"
            return 1
        fi
    fi
    
    echo ""
    
    # Ensure proper permissions on SSH files
    echo "🔒 Setting SSH file permissions..."
    
    # Set proper permissions on SSH directory and files
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_PRIVATE_KEY" "$ssh_config"
    chmod 644 "$SSH_PUBLIC_KEY"
    
    echo "✅ SSH file permissions set correctly"
    echo ""
    
    # Check SSH agent and add key if needed
    echo "🔄 Checking SSH agent configuration..."
    
    if add_ssh_key_to_agent; then
        echo "✅ SSH key added to agent and keychain"
    else
        echo "⚠️  Failed to add SSH key to agent/keychain"
        echo "   You may need to add it manually: ssh-add ~/.ssh/id_rsa"
    fi
    
    echo ""
    
    # Test SSH connectivity to common services
    echo "🌐 Testing SSH connectivity..."
    
    # Test GitHub SSH connection
    echo "   Testing GitHub SSH connection..."
    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "   ✅ GitHub SSH connection working"
    else
        echo "   ⚠️  GitHub SSH connection test inconclusive"
        echo "      This may be normal if you haven't added your public key to GitHub"
    fi
    
    # Check if ssh-agent is running and has our key
    echo "   Checking SSH agent key list..."
    if ssh-add -l 2>/dev/null | grep -q "$SSH_PUBLIC_KEY" || ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$SSH_PUBLIC_KEY" | awk '{print $2}')"; then
        echo "   ✅ SSH key is loaded in agent"
    else
        echo "   ⚠️  SSH key not found in agent"
        echo "      Run: ssh-add ~/.ssh/id_rsa"
    fi
    
    echo ""
    
    # Display public key for easy copying
    echo "📋 Your SSH public key (for adding to services):"
    echo ""
    if [[ -r "$SSH_PUBLIC_KEY" ]]; then
        cat "$SSH_PUBLIC_KEY"
    else
        echo "❌ Cannot read public key file: $SSH_PUBLIC_KEY"
    fi
    
    echo ""
    echo "🎉 SSH configuration update completed"
    echo ""
    echo "Summary of updates:"
    echo "  - SSH key pair validated"
    echo "  - SSH config file checked/updated"
    echo "  - File permissions set correctly"
    echo "  - SSH agent configuration verified"
    echo "  - Connectivity tests performed"
    echo ""
    echo "Next steps:"
    echo "  - Add your public key to GitHub/GitLab/etc if not already done"
    echo "  - Test SSH connections: ssh -T git@github.com"
    echo "  - If issues persist, check: ssh -vT git@github.com"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi