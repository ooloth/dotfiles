#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

source "${DOTFILES}/tools/macos/shell/aliases.zsh"
source "${DOTFILES}/features/common/errors.bash"

# Check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if softwareupdate command is available
is_softwareupdate_available() {
    command -v softwareupdate >/dev/null 2>&1
}

# Validate macOS environment for updates
validate_macos_update_environment() {
    if ! is_macos; then
        echo "❌ macOS system updates can only be performed on macOS"
        return 1
    fi

    if ! is_softwareupdate_available; then
        echo "❌ softwareupdate command not available"
        return 1
    fi

    if is_work; then
        echo "⏭️  Skipping macOS updates on work machine to avoid policy conflicts"
        return 2 # Special return code for work machine skip
    fi
}

# Check if user has admin privileges
has_admin_privileges() {
    # Check if user is in admin group
    groups | grep -q admin
}

# Configure general macOS settings
configure_general_settings() {
    echo "🔧 Configuring general settings..."

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    echo "  • Expand save dialog by default"

    # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    echo "  • Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"

    # Enable subpixel font rendering on non-Apple LCDs
    # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
    defaults write NSGlobalDomain AppleFontSmoothing -int 1
    echo "  • Enable subpixel font rendering on non-Apple LCDs"

    echo "✅ General settings configured successfully"
    return 0
}

# Configure Finder settings
configure_finder_settings() {
    echo "🔍 Configuring Finder..."

    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    echo "  • Show all filename extensions"

    # Hide hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool false
    echo "  • Hide hidden files by default"

    # Use current directory as default search scope in Finder
    # This Mac       : `SCev`
    # Current Folder : `SCcf`
    # Previous Scope : `SCsp`
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    echo "  • Use current directory as default search scope in Finder"

    # Show Path bar in Finder
    defaults write com.apple.finder ShowPathbar -bool true
    echo "  • Show Path bar in Finder"

    # Show Status bar in Finder
    defaults write com.apple.finder ShowStatusBar -bool true
    echo "  • Show Status bar in Finder"

    # Show the ~/Library folder in Finder
    chflags nohidden ~/Library
    echo "  • Show the ~/Library folder in Finder"

    echo "✅ Finder settings configured successfully"
    return 0
}

# Configure Safari settings
configure_safari_settings() {
    echo "🌐 Configuring Safari..."

    # Enable Safari's debug menu
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    echo "  • Enable Safari's debug menu"

    echo "✅ Safari settings configured successfully"
    return 0
}

main() {
    echo "💻 Configuring macOS system settings"
    echo ""

    # Check if we're on macOS
    if ! is_macos; then
        echo "⏭️  Skipping settings configuration (not on macOS)"
        return 0
    fi

    # Configure general settings
    if ! configure_general_settings; then
        echo "❌ Failed to configure general settings"
        exit 1
    fi

    # Configure Finder
    if ! configure_finder_settings; then
        echo "❌ Failed to configure Finder settings"
        exit 1
    fi

    # Configure Safari
    if ! configure_safari_settings; then
        echo "❌ Failed to configure Safari settings"
        exit 1
    fi

    echo ""
    echo "🎉 macOS system settings configuration complete!"
}

# Run main function
main "$@"
