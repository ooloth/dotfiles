#!/usr/bin/env bash

# Homebrew Installation Script
# Installs and configures Homebrew package manager for macOS

set -euo pipefail

# Source utility functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_root="$(cd "$script_dir/../.." && pwd)"

source "$dotfiles_root/lib/homebrew-utils.bash"

# Main installation function
install_homebrew() {
    echo "🍺 Setting up Homebrew..."
    
    # Check if Homebrew is already installed
    if detect_homebrew; then
        # Ensure it's properly configured
        ensure_homebrew_in_path
        
        # Validate the installation
        if validate_homebrew_installation; then
            echo "✅ Homebrew is already installed and functional"
            return 0
        else
            echo "⚠️  Homebrew found but not functional, attempting to fix..."
        fi
    else
        echo "📦 Installing Homebrew..."
        
        # Install Homebrew using official installation script
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            echo "❌ Failed to install Homebrew" >&2
            return 1
        fi
        
        echo "✅ Homebrew installation completed"
    fi
    
    # Ensure Homebrew is in PATH after installation
    ensure_homebrew_in_path
    
    # Final validation
    if validate_homebrew_installation; then
        echo "✅ Homebrew installation and configuration successful"
        
        # Display version information
        echo "🔍 Homebrew information:"
        get_homebrew_version
        
        return 0
    else
        echo "❌ Homebrew installation failed validation" >&2
        return 1
    fi
}

# Install packages from Brewfile if it exists
install_brewfile_packages() {
    local brewfile_path="$dotfiles_root/macos/Brewfile"
    
    if [[ -f "$brewfile_path" ]]; then
        echo "📦 Installing packages from Brewfile..."
        
        # Use brew bundle to install packages
        if brew bundle --file="$brewfile_path"; then
            echo "✅ Brewfile packages installed successfully"
        else
            echo "⚠️  Some Brewfile packages may have failed to install" >&2
            # Don't fail the entire script for package installation issues
        fi
    else
        echo "📦 No Brewfile found at $brewfile_path, skipping package installation"
    fi
}

# Update Homebrew and installed packages
update_homebrew() {
    echo "🔄 Updating Homebrew and packages..."
    
    if brew update && brew upgrade; then
        echo "✅ Homebrew update completed"
    else
        echo "⚠️  Homebrew update encountered issues" >&2
        # Don't fail for update issues
    fi
}

# Main execution
main() {
    local action="${1:-install}"
    
    case "$action" in
        "install")
            install_homebrew
            install_brewfile_packages
            ;;
        "update")
            # Ensure Homebrew is available first
            ensure_homebrew_in_path
            update_homebrew
            ;;
        "packages")
            # Ensure Homebrew is available first
            ensure_homebrew_in_path
            install_brewfile_packages
            ;;
        *)
            echo "Usage: $0 [install|update|packages]" >&2
            echo "  install  - Install Homebrew and packages (default)" >&2
            echo "  update   - Update Homebrew and packages" >&2
            echo "  packages - Install only Brewfile packages" >&2
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi