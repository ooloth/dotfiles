#!/usr/bin/env bash

# See: https://docs.brew.sh/Brew-Bundle-and-Brewfile

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"
BREWFILE_PATH="$DOTFILES/homebrew/config/Brewfile"

# Load utilities
# shellcheck source=homebrew/utils.bash
source "$DOTFILES/homebrew/utils.bash"

main() {
    echo "🍺 Updating Homebrew and packages..."
    echo ""

    # Ensure Homebrew is available
    if ! detect_homebrew; then
        echo "❌ Homebrew is not installed."
        echo "   Please install Homebrew first, then run the install script:"
        echo "   ./homebrew/install.bash"
        echo ""
        return 1
    fi

    # Ensure Homebrew is in PATH
    ensure_homebrew_in_path

    # Validate Homebrew installation
    if ! validate_homebrew_installation; then
        echo "❌ Homebrew installation validation failed"
        echo "   Please check your Homebrew installation: brew doctor"
        echo ""
        return 1
    fi

    # Display current Homebrew version
    local homebrew_version
    if homebrew_version=$(get_homebrew_version | head -1); then
        echo "📦 Current Homebrew: $homebrew_version"
    fi

    echo ""

    # Verify Brewfile exists
    if [[ ! -f "$BREWFILE_PATH" ]]; then
        echo "❌ Brewfile not found: $BREWFILE_PATH"
        echo "   Please ensure the Brewfile exists in the expected location"
        return 1
    fi

    echo "📋 Using Brewfile: $BREWFILE_PATH"
    echo ""

    # Update Homebrew itself
    echo "🔄 Updating Homebrew..."
    if brew update; then
        echo "✅ Homebrew updated successfully"
    else
        echo "❌ Failed to update Homebrew"
        return 1
    fi

    echo ""

    # Install/remove packages according to Brewfile and clean up unlisted ones
    echo "📦 Syncing packages with Brewfile..."
    echo "   Installing new packages and removing unlisted ones..."
    if brew bundle --file="$BREWFILE_PATH" --cleanup; then
        echo "✅ Brewfile sync completed successfully"
    else
        echo "❌ Brewfile sync failed"
        return 1
    fi

    echo ""

    # Update all installed packages
    echo "⬆️  Upgrading all installed packages..."
    if brew upgrade; then
        echo "✅ All packages upgraded successfully"
    else
        echo "⚠️  Some packages failed to upgrade"
        echo "   Continuing with cask updates..."
    fi

    echo ""

    # Update casks (GUI applications)
    echo "📱 Updating casks..."
    if command -v brew >/dev/null 2>&1 && brew list --cask >/dev/null 2>&1; then
        # Check if brew-cask-upgrade is available
        if brew list --formula | grep -q "^buo$" || command -v brew-cu >/dev/null 2>&1; then
            if brew cu --all --yes --cleanup; then
                echo "✅ Casks updated successfully"
            else
                echo "⚠️  Some casks failed to update"
            fi
        else
            echo "💡 brew-cask-upgrade not installed, skipping automatic cask updates"
            echo "   Install with: brew install buo"
            echo "   Or update casks manually: brew outdated --cask"
        fi
    else
        echo "💡 No casks installed, skipping cask updates"
    fi

    echo ""

    # Clean up old versions and cached files
    echo "🧹 Cleaning up old versions and cache..."

    # Remove old versions
    if brew autoremove; then
        echo "✅ Old dependencies removed"
    else
        echo "⚠️  Failed to remove some old dependencies"
    fi

    # Clean up cache and downloads
    if brew cleanup; then
        echo "✅ Cache and downloads cleaned"
    else
        echo "⚠️  Failed to clean some cache files"
    fi

    echo ""

    # Run brew doctor to check for issues
    echo "🩺 Running Homebrew diagnostics..."
    if brew doctor; then
        echo "✅ Homebrew diagnostics passed"
    else
        echo "⚠️  Homebrew diagnostics found issues"
        echo "   Review the output above and address any warnings"
    fi

    echo ""
    echo "🎉 Homebrew update completed"
    echo ""
    echo "Summary of updates:"
    echo "  - Homebrew itself updated"
    echo "  - Packages synced with Brewfile"
    echo "  - All packages upgraded to latest versions"
    echo "  - Casks updated (if brew-cask-upgrade available)"
    echo "  - Old versions and cache cleaned up"
    echo "  - System diagnostics run"
    echo ""
    echo "Next steps:"
    echo "  - Review any warnings from 'brew doctor'"
    echo "  - Check if any manual cask updates are needed: brew outdated --cask"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

