#!/usr/bin/env zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "💻 Configuring macOS system settings"

printf "Configuring general settings...\n"

printf "Expand save dialog by default\n"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

printf "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)\n"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

printf "Enable subpixel font rendering on non-Apple LCDs\n"
defaults write NSGlobalDomain AppleFontSmoothing -int 2

printf "\n"
info "Configuring Finder...\n"

printf "Show all filename extensions\n"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

printf "Show hidden files by default\n"
defaults write com.apple.Finder AppleShowAllFiles -bool false

printf "Use current directory as default search scope in Finder\n"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

printf "Show Path bar in Finder\n"
defaults write com.apple.finder ShowPathbar -bool true

printf "Show Status bar in Finder\n"
defaults write com.apple.finder ShowStatusBar -bool true

printf "Show the ~/Library folder in Finder\n"
chflags nohidden ~/Library

printf "\n"
info "Configuring Safari...\n"

printf "Enable Safari’s debug menu\n"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

printf "\n🚀 Done configuring Mac system preferences.\n"
