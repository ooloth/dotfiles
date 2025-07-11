#!/usr/bin/env bash

# Neovim installation utilities
# Provides functions for managing Neovim configuration

set -euo pipefail

# Check if Neovim config is installed
neovim_config_installed() {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    [ -d "$config_dir" ]
}