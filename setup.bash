#!/usr/bin/env bash

# Dotfiles setup script (bash version)
# Main entry point for dotfiles installation

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="$HOME/Repos/ooloth/dotfiles"

# Main installation function
main() {
    printf "\nWelcome to your new Mac! This installation will perform the following steps:\n\n"
    printf "1. Confirm this is a Mac\n"
    printf "2. Ask you to enter your password\n"
    printf "3. Confirm the Command Line Developer Tools are installed\n"
    printf "4. Clone ooloth/dotfiles\n"
    printf "5. Create your SSH keys\n"
    printf "6. Confirm you can SSH to GitHub\n"
    printf "7. Install Homebrew\n"
    printf "8. Install the packages, casks, App Store apps and VS Code extensions listed in your Brewfile\n"
    printf "9. Configure your Mac to use the Homebrew version of Zsh\n"
    printf "10. Install rust (if not work computer)\n"
    printf "11. Install uv\n"
    printf "12. Install the latest version of Node via fnm and set it as the default\n"
    printf "13. Install global npm dependencies\n"
    printf "14. Install tmux dependencies\n"
    printf "15. Install neovim dependencies\n"
    printf "16. Install yazi flavors (if not work computer)\n"
    printf "17. Symlink your dotfiles to your home and library directories\n"
    printf "18. Update macOS system settings\n\n"

    printf "Sound good? (y/N) "
    read -r key

    if [[ ! "$key" == 'y' ]]; then
        printf "\nNo worries! Maybe next time."
        printf "\nExiting...\n"
        exit 1
    else
        printf "\nExcellent! Here we go...\n\n"
    fi
    
    # Confirm this is a Mac
    printf "Confirming this is a Mac...\n\n"
    
    if [[ "$(uname)" != "Darwin" ]]; then
        printf "Error: This script only runs on macOS.\n"
        exit 1
    else
        printf "✓ macOS confirmed.\n\n"
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi