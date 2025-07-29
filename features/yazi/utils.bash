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

# Check if sufficient disk space is available
check_disk_space() {
    local target_path="$1"
    local required_mb="${2:-50}"  # Default 50MB
    
    # Get parent directory for space check
    local parent_dir
    parent_dir="$(dirname "$target_path")"
    mkdir -p "$parent_dir"
    
    # Get available space in MB (works on both macOS and Linux)
    local available_mb
    if command -v df >/dev/null 2>&1; then
        available_mb=$(df -m "$parent_dir" | awk 'NR==2 {print $4}')
        if [[ "$available_mb" -ge "$required_mb" ]]; then
            return 0
        else
            echo "❌ Insufficient disk space: ${available_mb}MB available, ${required_mb}MB required" >&2
            return 1
        fi
    else
        # Fallback if df is not available - assume space is available
        echo "⚠️  Cannot check disk space, proceeding anyway" >&2
        return 0
    fi
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
    
    # Check available disk space
    if ! check_disk_space "$YAZI_FLAVORS_PATH" "50"; then
        return 1
    fi
    
    echo "📦 Cloning yazi flavors repository..."
    
    # Create parent directory
    local parent_dir
    parent_dir="$(dirname "$YAZI_FLAVORS_PATH")"
    mkdir -p "$parent_dir"
    
    # Try SSH first, fallback to HTTPS
    if ! timeout 30 git clone "git@github.com:$YAZI_FLAVORS_REPO.git" "$YAZI_FLAVORS_PATH" 2>/dev/null; then
        echo "SSH clone failed, trying HTTPS..."
        if ! timeout 30 git clone "https://github.com/$YAZI_FLAVORS_REPO.git" "$YAZI_FLAVORS_PATH"; then
            echo "❌ Failed to clone yazi flavors repository" >&2
            rm -rf "$YAZI_FLAVORS_PATH" 2>/dev/null || true
            return 1
        fi
    fi
    
    # Validate expected content exists
    if [[ ! -d "$YAZI_FLAVORS_PATH/$YAZI_THEME" ]]; then
        echo "❌ Expected theme not found in cloned repository: $YAZI_THEME" >&2
        rm -rf "$YAZI_FLAVORS_PATH"
        return 1
    fi
    
    echo "✅ Yazi flavors cloned and validated successfully"
    return 0
}

# Create symlink for yazi theme
setup_yazi_theme() {
    local theme_source="$YAZI_FLAVORS_PATH/$YAZI_THEME"
    local theme_target="$YAZI_CONFIG_DIR/flavors"
    
    if [[ ! -d "$theme_source" ]]; then
        echo "❌ Theme not found: $theme_source" >&2
        return 1
    fi
    
    # Verify source is within expected directory (prevent directory traversal)
    if [[ ! "$theme_source" == "$YAZI_FLAVORS_PATH"/* ]]; then
        echo "❌ Invalid theme path detected" >&2
        return 1
    fi
    
    echo "🎨 Setting up yazi theme..."
    
    # Create config directory if needed
    mkdir -p "$YAZI_CONFIG_DIR"
    
    # Create backup of existing target if it's not a symlink
    if [[ -e "$theme_target" && ! -L "$theme_target" ]]; then
        local backup_path
        backup_path="${theme_target}.backup.$(date +%s)"
        echo "📦 Backing up existing target to: $backup_path"
        mv "$theme_target" "$backup_path"
    fi
    
    # Create symlink
    if ln -sfv "$theme_source" "$theme_target"; then
        echo "✅ Yazi theme symlinked successfully"
        return 0
    else
        echo "❌ Failed to create theme symlink" >&2
        return 1
    fi
}