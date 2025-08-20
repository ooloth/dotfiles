#!/usr/bin/env bash

# Settings utilities for macOS system preferences

set -euo pipefail

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