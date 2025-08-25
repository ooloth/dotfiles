#!/usr/bin/env bash

# SSH utility functions for installation scripts
# Provides reusable functionality for detecting and working with SSH keys

set -euo pipefail

# Get SSH key paths (centralized configuration)
get_ssh_key_paths() {
    SSH_DIR="${HOME}/.ssh"
    SSH_PRIVATE_KEY="${SSH_DIR}/id_rsa"
    SSH_PUBLIC_KEY="${SSH_DIR}/id_rsa.pub"
}

# Check if SSH keys exist on the system (no output)
# Returns: 0 if both private and public keys exist, 1 if not
ssh_keys_exist() {
    get_ssh_key_paths
    [[ -s "$SSH_PRIVATE_KEY" && -s "$SSH_PUBLIC_KEY" ]]
}

# Detect if SSH keys exist on the system (with output)
# Prints informative messages and returns appropriate exit codes
# Returns: 0 if both private and public keys exist, 1 if not
detect_ssh_keys() {
    if ssh_keys_exist; then
        echo "✅ SSH key pair found."
        return 0
    else
        echo "👎 No SSH key pair found."
        return 1
    fi
}

# Create SSH config file with appropriate settings
# Arguments: $1 - SSH config file path
create_ssh_config() {
    local ssh_config="$1"
    local ssh_dir
    ssh_dir=$(dirname "$ssh_config")
    
    get_ssh_key_paths
    
    mkdir -p "$ssh_dir"
    
    cat > "$ssh_config" << EOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_PRIVATE_KEY
EOF
}

# Check if SSH config has all required settings
# Arguments: $1 - SSH config file path
# Returns: 0 if all settings present, 1 if any missing
ssh_config_has_required_settings() {
    local ssh_config="$1"
    
    if [[ ! -f "$ssh_config" ]]; then
        return 1
    fi
    
    get_ssh_key_paths
    
    # Check each required setting
    grep -Fxq "Host *" "$ssh_config" && \
    grep -Fxq "  AddKeysToAgent yes" "$ssh_config" && \
    grep -Fxq "  UseKeychain yes" "$ssh_config" && \
    grep -Fxq "  IdentityFile $SSH_PRIVATE_KEY" "$ssh_config"
}

# Generate SSH key pair
# Returns: 0 on success, 1 on failure
generate_ssh_keys() {
    get_ssh_key_paths
    
    # Generate a 2048-bit RSA SSH key pair
    # -q makes the process quiet
    # -N '' sets an empty passphrase
    # -f specifies the output file
    ssh-keygen -q -t rsa -b 2048 -N '' -f "$SSH_PRIVATE_KEY" <<< y >/dev/null 2>&1
}

# Add SSH key to ssh-agent and Keychain
# Returns: 0 on success, 1 on failure
add_ssh_key_to_agent() {
    get_ssh_key_paths
    
    # Start ssh-agent if not running
    if ! ssh-add -l >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    
    # Add key to agent and keychain
    # Note: -K flag is deprecated on newer macOS, use --apple-use-keychain instead
    if command -v sw_vers >/dev/null 2>&1 && [[ $(sw_vers -productVersion | cut -d. -f1) -ge 12 ]]; then
        # macOS 12 (Monterey) and later
        ssh-add --apple-use-keychain "$SSH_PRIVATE_KEY" 2>/dev/null
    else
        # Older macOS versions
        ssh-add -K "$SSH_PRIVATE_KEY" 2>/dev/null
    fi
}