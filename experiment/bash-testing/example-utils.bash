#!/usr/bin/env bash

# Example utilities for testing bash + shellcheck + bats approach
# This mirrors some functionality from our existing SSH utilities

set -euo pipefail

# Check if a command exists
command_exists() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1
}

# Detect if SSH keys exist (similar to our SSH utils)
detect_ssh_keys() {
    local ssh_dir="${HOME}/.ssh"
    local private_key="${ssh_dir}/id_rsa"
    local public_key="${ssh_dir}/id_rsa.pub"
    
    if [[ -s "$private_key" && -s "$public_key" ]]; then
        echo "✅ SSH key pair found."
        return 0
    else
        echo "👎 No SSH key pair found."
        return 1
    fi
}

# Validate homebrew installation (similar to our Homebrew utils)
validate_homebrew() {
    if ! command_exists "brew"; then
        echo "❌ Homebrew not found"
        return 1
    fi
    
    echo "✅ Homebrew found"
    return 0
}