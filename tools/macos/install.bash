#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

source "${DOTFILES}/features/common/errors.bash"

# Check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if softwareupdate command is available
is_softwareupdate_available() {
    command -v softwareupdate >/dev/null 2>&1
}

# Check if system_profiler command is available
is_system_profiler_available() {
    command -v system_profiler >/dev/null 2>&1
}

# Get macOS version
get_macos_version() {
    if is_macos && is_system_profiler_available; then
        system_profiler SPSoftwareDataType | awk '/System Version/ {print $4" "$5" "$6}'
    else
        echo "unknown"
    fi
}

# Get macOS build number
get_macos_build() {
    if is_macos && is_system_profiler_available; then
        system_profiler SPSoftwareDataType | awk '/System Version/ {print $NF}' | tr -d '()'
    else
        echo "unknown"
    fi
}

# Check for available software updates
check_software_updates() {
    if ! is_softwareupdate_available; then
        echo "❌ softwareupdate command not available"
        return 1
    fi

    echo "🔍 Checking for macOS software updates..."
    softwareupdate --list 2>/dev/null
}

# Install all available software updates
install_software_updates() {
    local restart_flag="${1:-true}"

    if ! is_softwareupdate_available; then
        echo "❌ softwareupdate command not available"
        return 1
    fi

    echo "📦 Installing macOS software updates..."
    echo "⚠️  System may restart automatically during installation"

    local cmd_args=(
        "--install"
        "--all"
        "--agree-to-license"
        "--verbose"
    )

    # Add restart flag if requested
    if [[ "$restart_flag" == "true" ]]; then
        cmd_args+=("--restart")
    fi

    # Run with sudo
    if ! sudo softwareupdate "${cmd_args[@]}"; then
        echo "❌ Failed to install software updates"
        return 1
    fi
}

# Check if system needs restart for updates
needs_restart_for_updates() {
    if ! is_softwareupdate_available; then
        return 1
    fi

    # Check if there are updates that require restart
    softwareupdate --list 2>/dev/null | grep -q "restart"
}

# Get system uptime
get_system_uptime() {
    if is_macos; then
        uptime | awk '{print $3" "$4}' | sed 's/,$//'
    else
        echo "unknown"
    fi
}

# Check if running on work machine
is_work_machine() {
    # This can be overridden by environment variable or machine detection
    [[ "${IS_WORK:-false}" == "true" ]]
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

    if is_work_machine; then
        echo "⏭️  Skipping macOS updates on work machine to avoid policy conflicts"
        return 2 # Special return code for work machine skip
    fi
}

# Get detailed system information
get_system_info() {
    if ! is_macos; then
        echo "System: Non-macOS"
        return
    fi

    echo "System: macOS $(get_macos_version)"
    echo "Build: $(get_macos_build)"
    echo "Uptime: $(get_system_uptime)"
}

# Check if user has admin privileges
has_admin_privileges() {
    # Check if user is in admin group
    groups | grep -q admin
}

# Warn about potential restart
warn_about_restart() {
    echo ""
    echo "⚠️  WARNING: macOS software updates may restart your system automatically!"
    echo "📋 Save your work and close important applications before proceeding."
    echo ""
}

# Check for specific macOS version compatibility
is_supported_macos_version() {
    local min_version="${1:-10.14}" # Default to Mojave

    if ! is_macos; then
        return 1
    fi

    local current_version
    current_version=$(sw_vers -productVersion 2>/dev/null || echo "0.0")

    # Simple version comparison (works for x.y format)
    [[ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" == "$min_version" ]]
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
