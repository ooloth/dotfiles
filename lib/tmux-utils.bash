#!/usr/bin/env bash

# Tmux installation utilities
# Provides functions for managing Tmux Plugin Manager (TPM)

set -euo pipefail

# Check if TPM is installed
tpm_installed() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    [ -d "$tpm_dir" ]
}

# Install Tmux Plugin Manager
install_tpm() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    
    echo "🍱 Installing tpm"
    
    # Clone TPM repository
    git clone "git@github.com:tmux-plugins/tpm.git" "$tpm_dir"
}

# Install TPM plugins
install_tpm_plugins() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    
    echo "🍱 Installing tpm plugins"
    
    # Run TPM install script
    "$tpm_dir/bin/install_plugins"
    
    echo "🚀 Finished installing tmux"
}