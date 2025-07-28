#!/usr/bin/env bash
# Utilities for managing macOS system settings

set -euo pipefail

# Check if defaults command is available
is_defaults_available() {
  command -v defaults >/dev/null 2>&1
}

# Check if chflags command is available
is_chflags_available() {
  command -v chflags >/dev/null 2>&1
}

# Apply a defaults setting
apply_defaults_setting() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"
  local description="$5"
  
  echo "$description"
  
  if ! defaults write "$domain" "$key" "-$type" "$value"; then
    echo "❌ Failed to set $domain $key"
    return 1
  fi
}

# Apply boolean defaults setting
apply_bool_setting() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local description="$4"
  
  apply_defaults_setting "$domain" "$key" "bool" "$value" "$description"
}

# Apply integer defaults setting
apply_int_setting() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local description="$4"
  
  apply_defaults_setting "$domain" "$key" "int" "$value" "$description"
}

# Apply string defaults setting
apply_string_setting() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local description="$4"
  
  apply_defaults_setting "$domain" "$key" "string" "$value" "$description"
}

# Configure general macOS settings
configure_general_settings() {
  echo "Configuring general settings..."
  echo ""
  
  apply_bool_setting "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode" "true" \
    "Expand save dialog by default"
  
  apply_int_setting "NSGlobalDomain" "AppleKeyboardUIMode" "3" \
    "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
  
  apply_int_setting "NSGlobalDomain" "AppleFontSmoothing" "2" \
    "Enable subpixel font rendering on non-Apple LCDs"
}

# Configure Finder settings
configure_finder_settings() {
  echo ""
  echo "🔍 Configuring Finder..."
  echo ""
  
  apply_bool_setting "NSGlobalDomain" "AppleShowAllExtensions" "true" \
    "Show all filename extensions"
  
  apply_bool_setting "com.apple.Finder" "AppleShowAllFiles" "false" \
    "Show hidden files by default"
  
  apply_string_setting "com.apple.finder" "FXDefaultSearchScope" "SCcf" \
    "Use current directory as default search scope in Finder"
  
  apply_bool_setting "com.apple.finder" "ShowPathbar" "true" \
    "Show Path bar in Finder"
  
  apply_bool_setting "com.apple.finder" "ShowStatusBar" "true" \
    "Show Status bar in Finder"
  
  echo "Show the ~/Library folder in Finder"
  if ! chflags nohidden ~/Library; then
    echo "❌ Failed to unhide ~/Library folder"
    return 1
  fi
}

# Configure Safari settings
configure_safari_settings() {
  echo ""
  echo "🌐 Configuring Safari..."
  echo ""
  
  # Note: This setting may not work on newer macOS versions
  apply_bool_setting "com.apple.Safari" "IncludeInternalDebugMenu" "true" \
    "Enable Safari's debug menu"
}

# Check if running on macOS
is_macos() {
  [[ "$(uname)" == "Darwin" ]]
}

# Validate that we're on macOS before applying settings
validate_macos_environment() {
  if ! is_macos; then
    echo "❌ macOS system settings can only be applied on macOS"
    return 1
  fi
  
  if ! is_defaults_available; then
    echo "❌ defaults command not available"
    return 1
  fi
  
  if ! is_chflags_available; then
    echo "❌ chflags command not available"
    return 1
  fi
}