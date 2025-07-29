#!/usr/bin/env bash

# Yazi utilities for dotfiles setup

set -euo pipefail

# Configuration
YAZI_FLAVORS_REPO="yazi-rs/flavors"
YAZI_FLAVORS_PATH="$HOME/Repos/$YAZI_FLAVORS_REPO"
YAZI_CONFIG_DIR="$HOME/.config/yazi"
YAZI_THEME="catppuccin-mocha.yazi"

# Check if yazi flavors are already installed
is_yazi_flavors_installed() {
    [[ -d "$YAZI_FLAVORS_PATH" ]]
}

# Get yazi flavors installation path
get_yazi_flavors_path() {
    echo "$YAZI_FLAVORS_PATH"
}

# Get yazi config directory
get_yazi_config_dir() {
    echo "$YAZI_CONFIG_DIR"
}

# Install yazi flavors repository
install_yazi_flavors() {
    if [[ -d "$YAZI_FLAVORS_PATH" ]]; then
        echo "✅ Yazi flavors already installed at: $YAZI_FLAVORS_PATH"
        return 0
    fi
    
    echo "📦 Cloning yazi flavors repository..."
    
    # Create parent directory
    local parent_dir
    parent_dir="$(dirname "$YAZI_FLAVORS_PATH")"
    mkdir -p "$parent_dir"
    
    # Clone repository
    if git clone "git@github.com:$YAZI_FLAVORS_REPO.git" "$YAZI_FLAVORS_PATH"; then
        echo "✅ Yazi flavors cloned successfully"
        return 0
    else
        echo "❌ Failed to clone yazi flavors repository" >&2
        return 1
    fi
}

# Create symlink for yazi theme
setup_yazi_theme() {
    local theme_source="$YAZI_FLAVORS_PATH/$YAZI_THEME"
    local theme_target="$YAZI_CONFIG_DIR/flavors"
    
    if [[ ! -d "$theme_source" ]]; then
        echo "❌ Theme not found: $theme_source" >&2
        return 1
    fi
    
    echo "🎨 Setting up yazi theme..."
    
    # Create config directory if needed
    mkdir -p "$YAZI_CONFIG_DIR"
    
    # Create symlink
    if ln -sfv "$theme_source" "$theme_target"; then
        echo "✅ Yazi theme symlinked successfully"
        return 0
    else
        echo "❌ Failed to create theme symlink" >&2
        return 1
    fi
}