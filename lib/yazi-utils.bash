#!/usr/bin/env bash
# Utilities for managing Yazi file manager flavors and configuration

set -euo pipefail

# Check if yazi flavors repository is already cloned
is_yazi_flavors_installed() {
  local repo_path="${1:-$HOME/Repos/yazi-rs/flavors}"
  [[ -d "$repo_path" ]]
}

# Clone yazi flavors repository
clone_yazi_flavors() {
  local repo_url="${1:-git@github.com:yazi-rs/flavors.git}"
  local repo_path="${2:-$HOME/Repos/yazi-rs/flavors}"
  
  echo "📂 Installing yazi flavors"
  
  # Create parent directory
  mkdir -p "$(dirname "$repo_path")"
  
  # Clone the repository
  if ! git clone "$repo_url" "$repo_path"; then
    echo "❌ Failed to clone yazi flavors repository"
    return 1
  fi
}

# Create symlink for catppuccin-mocha theme
setup_yazi_theme_symlink() {
  local flavors_path="${1:-$HOME/Repos/yazi-rs/flavors}"
  local config_dir="${2:-$HOME/.config/yazi/flavors}"
  local theme="${3:-catppuccin-mocha.yazi}"
  
  local source_path="$flavors_path/$theme"
  
  # Check if source theme exists
  if [[ ! -d "$source_path" ]]; then
    echo "❌ Theme $theme not found in flavors repository"
    return 1
  fi
  
  # Create config directory if it doesn't exist
  mkdir -p "$config_dir"
  
  # Create symlink
  if ! ln -sfv "$source_path" "$config_dir"; then
    echo "❌ Failed to create symlink for yazi theme"
    return 1
  fi
}

# Check if yazi config directory exists
yazi_config_exists() {
  local config_dir="${1:-$HOME/.config/yazi}"
  [[ -d "$config_dir" ]]
}

# Get yazi flavors repository path
get_yazi_flavors_path() {
  echo "$HOME/Repos/yazi-rs/flavors"
}

# Check if a specific theme is symlinked
is_theme_symlinked() {
  local theme="${1:-catppuccin-mocha.yazi}"
  local config_dir="${2:-$HOME/.config/yazi/flavors}"
  local theme_path="$config_dir/$theme"
  
  [[ -L "$theme_path" ]]
}