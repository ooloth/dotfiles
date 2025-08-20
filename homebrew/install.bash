#!/usr/bin/env bash

# Homebrew installation script
# Installs and configures Homebrew package manager for macOS
#
# This script:
# 1. Installs Homebrew if not present
# 2. Ensures Homebrew is properly configured in PATH
# 3. Updates Homebrew to latest version
# 4. Installs packages from Brewfile
# 5. Cleans up old/unused packages

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=homebrew/utils.bash
source "$DOTFILES/homebrew/utils.bash"

main() {
    echo "🍺 Installing Homebrew..."
    echo ""

    # Check if Homebrew is already installed
    if detect_homebrew; then
        # Ensure it's properly configured
        ensure_homebrew_in_path

        # Validate the installation
        if validate_homebrew_installation; then
            echo "✅ Homebrew is already installed and functional"
        else
            echo "⚠️  Homebrew found but not functional, attempting to fix..."
        fi
    else
        echo "📦 Installing Homebrew..."

        # Install Homebrew
        if install_homebrew_for_system; then
            echo "✅ Homebrew installed successfully"

            # Ensure it's in PATH
            ensure_homebrew_in_path
        else
            echo "❌ Failed to install Homebrew"
            return 1
        fi
    fi

    # Update Homebrew
    echo "🔄 Updating Homebrew..."
    if update_homebrew_packages; then
        echo "✅ Homebrew updated successfully"
    else
        echo "❌ Failed to update Homebrew"
        return 1
    fi

    # Install packages from Brewfile
    echo "📦 Installing packages from Brewfile..."
    local brewfile="$DOTFILES/homebrew/config/Brewfile"

    if [[ -f "$brewfile" ]]; then
        if install_packages_from_brewfile "$brewfile"; then
            echo "✅ Packages installed successfully"
        else
            echo "❌ Failed to install some packages"
            # Don't fail completely, just warn
        fi
    else
        echo "⚠️  No Brewfile found at $brewfile"
    fi

    # Clean up old packages
    echo "🧹 Cleaning up old packages..."
    if cleanup_homebrew_packages; then
        echo "✅ Cleanup completed successfully"
    else
        echo "⚠️  Cleanup completed with warnings"
    fi

    echo ""
    echo "🍺 Homebrew setup completed"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

