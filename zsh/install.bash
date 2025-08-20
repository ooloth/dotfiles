#!/usr/bin/env bash

# Zsh installation script
# Configures Zsh as the default shell with Homebrew installation
#
# This script:
# 1. Installs Zsh via Homebrew if not present
# 2. Adds Zsh to /etc/shells if not already listed
# 3. Changes user's default shell to Zsh
# 4. Validates the installation

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/zsh/utils.bash"

main() {
    echo "🐚 Installing and configuring Zsh shell..."
    echo ""

    local shell_path
    shell_path="$(get_zsh_shell_path)"

    # Check if Zsh is already installed
    if zsh_is_installed; then
        print_success "Zsh is already installed at $shell_path"
    else
        print_info "Zsh not found at $shell_path. Installing via Homebrew..."
        
        # Check if Homebrew is available
        if ! homebrew_is_installed; then
            print_error "Homebrew is required but not installed. Please install Homebrew first."
            return 1
        fi

        # Install Zsh via Homebrew
        if install_zsh_via_homebrew; then
            print_success "Zsh installed successfully"
            
            # Verify installation worked
            if ! zsh_is_installed; then
                print_error "Zsh installation failed - executable not found at $shell_path"
                return 1
            fi
        else
            print_error "Failed to install Zsh via Homebrew"
            return 1
        fi
    fi

    # Add Zsh to /etc/shells if not already present
    print_info "Ensuring Zsh is listed in /etc/shells..."
    if add_zsh_to_shells "$shell_path"; then
        print_success "Zsh added to /etc/shells"
    else
        print_error "Failed to add Zsh to /etc/shells"
        return 1
    fi

    # Change user's shell to Zsh
    print_info "Setting Zsh as default shell..."
    if user_shell_is_zsh "$shell_path"; then
        print_success "User shell is already set to Zsh"
    else
        if change_user_shell_to_zsh "$shell_path"; then
            print_success "User shell changed to Zsh"
            print_warning "You may need to restart your terminal or start a new session"
        else
            print_error "Failed to change user shell to Zsh"
            return 1
        fi
    fi

    # Validate the installation
    echo ""
    print_info "Validating Zsh installation..."
    if validate_zsh_installation "$shell_path"; then
        print_success "Zsh installation validation passed"
    else
        print_warning "Zsh installation validation had issues (see above)"
    fi

    # Validate Zsh configuration
    print_info "Validating Zsh configuration..."
    if validate_zsh_configuration; then
        print_success "Zsh configuration validation passed"
    else
        print_warning "Zsh configuration validation had issues (see above)"
    fi

    echo ""
    print_success "Zsh installation and configuration completed"
    print_info "Current shell: $SHELL"
    print_info "Zsh location: $shell_path"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
