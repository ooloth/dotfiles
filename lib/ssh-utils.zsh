#!/usr/bin/env zsh

# SSH utility functions for installation scripts
# Provides reusable functionality for detecting and working with SSH keys

# Detect if SSH keys exist on the system
# Prints informative messages and returns appropriate exit codes
# Returns: 0 if both private and public keys exist, 1 if not
detect_ssh_keys() {
    local ssh_dir="$HOME/.ssh"
    local private_key_path="$ssh_dir/id_rsa"
    local public_key_path="$ssh_dir/id_rsa.pub"
    
    if [[ -s "$private_key_path" && -s "$public_key_path" ]]; then
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
    local ssh_dir="$HOME/.ssh"
    local private_key_path="$ssh_dir/id_rsa"
    local public_key_path="$ssh_dir/id_rsa.pub"
    
    [[ -s "$private_key_path" && -s "$public_key_path" ]]
    return $?
}

# Get SSH public key content for display or copying
# Returns: 0 if key exists and content retrieved, 1 otherwise
get_ssh_public_key() {
    local ssh_dir="$HOME/.ssh"
    local public_key_path="$ssh_dir/id_rsa.pub"
    
    if [[ -s "$public_key_path" ]]; then
        cat "$public_key_path"
        return 0
    else
        echo "SSH public key not found"
        return 1
    fi
}