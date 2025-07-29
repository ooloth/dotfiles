#!/usr/bin/env bash

# Settings utilities
# Helper functions for macOS system settings configuration

set -euo pipefail

# Configure general macOS system settings
configure_general_settings() {
    echo "🔧 Configuring general settings..."
    
    echo "  • Expand save dialog by default"
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    
    echo "  • Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    
    echo "  • Enable subpixel font rendering on non-Apple LCDs"
    defaults write NSGlobalDomain AppleFontSmoothing -int 2
    
    echo "✅ General settings configured successfully"
    return 0
}

# Configure Finder settings
configure_finder_settings() {
    echo ""
    echo "🔍 Configuring Finder..."
    
    echo "  • Show all filename extensions"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    echo "  • Hide hidden files by default"
    defaults write com.apple.Finder AppleShowAllFiles -bool false
    
    echo "  • Use current directory as default search scope in Finder"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    
    echo "  • Show Path bar in Finder"
    defaults write com.apple.finder ShowPathbar -bool true
    
    echo "  • Show Status bar in Finder"
    defaults write com.apple.finder ShowStatusBar -bool true
    
    echo "  • Show the ~/Library folder in Finder"
    chflags nohidden ~/Library
    
    echo "✅ Finder settings configured successfully"
    return 0
}

# Configure Safari settings
configure_safari_settings() {
    echo ""
    echo "🌐 Configuring Safari..."
    
    # Note: This may not work on newer macOS versions
    echo "  • Enable Safari's debug menu"
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true || {
        echo "  ⚠️  Safari debug menu setting may not work on this macOS version"
    }
    
    echo "✅ Safari settings configured successfully"
    return 0
}