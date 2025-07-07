#!/usr/bin/env zsh

# SSH utility functions for installation scripts
# Provides reusable functionality for detecting and working with SSH keys

# Detect if SSH keys exist on the system
# Returns: 0 if both private and public keys exist, 1 if not
detect_ssh_keys() {
    local ssh_dir="$HOME/.ssh"
    local private_key_path="$ssh_dir/id_rsa"
    local public_key_path="$ssh_dir/id_rsa.pub"
    
    if [[ -s "$private_key_path" && -s "$public_key_path" ]]; then
        echo "SSH keys found"
        return 0
    else
        echo "SSH keys not found"
        return 1
    fi
}

# TODO: Use in bin/install/ssh.zsh for conditional key generation
# TODO: Use in prerequisite validation for SSH dependency checking