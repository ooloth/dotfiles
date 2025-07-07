#!/usr/bin/env zsh

# SSH utility functions for installation scripts
# Provides reusable functionality for detecting and working with SSH keys

# Get SSH key paths (centralized configuration)
_get_ssh_key_paths() {
    SSH_DIR="$HOME/.ssh"
    SSH_PRIVATE_KEY="$SSH_DIR/id_rsa"
    SSH_PUBLIC_KEY="$SSH_DIR/id_rsa.pub"
}

# Detect if SSH keys exist on the system
# Prints informative messages and returns appropriate exit codes
# Returns: 0 if both private and public keys exist, 1 if not
detect_ssh_keys() {
    _get_ssh_key_paths
    
    if [[ -s "$SSH_PRIVATE_KEY" && -s "$SSH_PUBLIC_KEY" ]]; then
        printf "✅ SSH key pair found.\n"
        return 0
    else
        printf "👎 No SSH key pair found.\n"
        return 1
    fi
}

# Check if SSH key pair files exist (both private and public)
# Returns: 0 if both keys exist and are non-empty, 1 otherwise
ssh_key_pair_found() {
    _get_ssh_key_paths
    
    [[ -s "$SSH_PRIVATE_KEY" && -s "$SSH_PUBLIC_KEY" ]]
    return $?
}

# Get SSH public key content for display or copying
# Returns: 0 if key exists and content retrieved, 1 otherwise
get_ssh_public_key() {
    _get_ssh_key_paths
    
    if [[ -s "$SSH_PUBLIC_KEY" ]]; then
        cat "$SSH_PUBLIC_KEY"
        return 0
    else
        echo "SSH public key not found"
        return 1
    fi
}