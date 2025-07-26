#!/usr/bin/env bash

# Neovim installation script (bash version)
# Clones Neovim configuration and restores plugins

set -euo pipefail

# Load Neovim utilities
source "${DOTFILES:-$HOME/Repos/ooloth/dotfiles}/lib/neovim-utils.bash"

main() {
    # Check if config is already installed
    if neovim_config_installed; then
        echo "📂 config.nvim is already installed"
        return 0
    fi
    
    # Clone the configuration
    clone_neovim_config
    
    # Restore plugins from lockfile
    restore_neovim_plugins
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi