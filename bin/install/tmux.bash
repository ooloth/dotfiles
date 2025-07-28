#!/usr/bin/env bash

# Tmux installation script (bash version)
# Installs Tmux Plugin Manager and plugins

set -euo pipefail

# Load Tmux utilities
source "${DOTFILES:-$HOME/Repos/ooloth/dotfiles}/lib/tmux-utils.bash"

main() {
    echo "🍱 Installing tpm and tmux plugins"
    
    # Check if TPM is already installed
    if tpm_installed; then
        echo "🍱 tpm is already installed"
    else
        # Install TPM
        install_tpm
    fi
    
    # Install plugins
    install_tpm_plugins
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi