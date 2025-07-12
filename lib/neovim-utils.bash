#!/usr/bin/env bash

# Neovim installation utilities
# Provides functions for managing Neovim configuration

set -euo pipefail

# Check if Neovim config is installed
neovim_config_installed() {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    [ -d "$config_dir" ]
}

# Clone Neovim configuration repository
clone_neovim_config() {
    local repo="ooloth/config.nvim"
    local local_repo="$HOME/Repos/$repo"
    
    echo "📂 Installing config.nvim"
    
    mkdir -p "$local_repo"
    git clone "git@github.com:$repo.git" "$local_repo"
}

# Restore Neovim plugins from lockfile
restore_neovim_plugins() {
    echo "📂 Installing Lazy plugin versions from lazy-lock.json"
    
    NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa
}