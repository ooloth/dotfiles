#!/usr/bin/env bash

# Zsh update script
# Updates Zsh and refreshes configuration
#
# This script:
# 1. Updates Zsh via Homebrew
# 2. Validates the updated installation
# 3. Refreshes Zsh configuration if needed

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/zsh/utils.bash"

main() {
    echo "🔄 Updating Zsh..."
    echo ""

    local shell_path
    shell_path="$(get_zsh_shell_path)"

    # Check if Zsh is installed
    if ! zsh_is_installed; then
        print_warning "Zsh is not installed. Run install.bash first."
        return 1
    fi

    # Update Zsh via Homebrew
    if homebrew_is_installed; then
        print_info "Updating Zsh via Homebrew..."
        if brew upgrade zsh 2>/dev/null || brew install zsh; then
            print_success "Zsh updated via Homebrew"
        else
            print_warning "Homebrew update may have failed or Zsh was already up to date"
        fi
    else
        print_warning "Homebrew not available - cannot update Zsh"
    fi

    # Ensure Zsh is still properly configured after update
    print_info "Verifying Zsh configuration after update..."
    
    # Re-add to /etc/shells if needed (update might have changed path)
    if add_zsh_to_shells "$shell_path"; then
        print_success "Zsh path verified in /etc/shells"
    else
        print_error "Failed to verify Zsh in /etc/shells"
        return 1
    fi

    # Verify user shell is still correct
    if user_shell_is_zsh "$shell_path"; then
        print_success "User shell correctly set to Zsh"
    else
        print_warning "User shell may need to be reset to Zsh: $shell_path"
        print_info "Run: sudo chsh -s $shell_path $USER"
    fi

    # Validate the updated installation
    echo ""
    print_info "Validating updated Zsh installation..."
    if validate_zsh_installation "$shell_path"; then
        print_success "Zsh installation validation passed"
    else
        print_warning "Zsh installation validation had issues (see above)"
    fi

    # Check configuration files
    print_info "Validating Zsh configuration files..."
    if validate_zsh_configuration; then
        print_success "Zsh configuration validation passed"
    else
        print_warning "Zsh configuration validation had issues (see above)"
    fi

    echo ""
    print_success "Zsh update completed"
    
    # Show current version information
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -n1 || echo "Unknown")
        print_info "Zsh version: $zsh_version"
    fi
    
    print_info "Zsh location: $shell_path"
    print_info "Current shell: $SHELL"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
