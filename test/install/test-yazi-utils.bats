#!/usr/bin/env bats

# Test suite for yazi-utils.bash

# Load the yazi utilities
load "../../lib/yazi-utils.bash"

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Save original HOME
  export ORIGINAL_HOME="$HOME"
  export HOME="$TEST_TEMP_DIR/fake_home"
  mkdir -p "$HOME"
}

teardown() {
  # Restore original HOME
  export HOME="$ORIGINAL_HOME"
  
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test is_yazi_flavors_installed
@test "is_yazi_flavors_installed returns true when repository exists" {
  local repo_path="$HOME/Repos/yazi-rs/flavors"
  mkdir -p "$repo_path"
  
  run is_yazi_flavors_installed "$repo_path"
  [ "$status" -eq 0 ]
}

@test "is_yazi_flavors_installed returns false when repository missing" {
  local repo_path="$HOME/Repos/yazi-rs/flavors"
  
  run is_yazi_flavors_installed "$repo_path"
  [ "$status" -ne 0 ]
}

@test "is_yazi_flavors_installed uses default path when not specified" {
  mkdir -p "$HOME/Repos/yazi-rs/flavors"
  
  run is_yazi_flavors_installed
  [ "$status" -eq 0 ]
}

# Test clone_yazi_flavors
@test "clone_yazi_flavors creates directory and runs git clone" {
  # Mock git command
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "GIT_CLONE: $*"
      mkdir -p "$3"  # Create the target directory
      return 0
    else
      command git "$@"
    fi
  }
  
  local repo_path="$HOME/Repos/yazi-rs/flavors"
  
  run clone_yazi_flavors "git@github.com:yazi-rs/flavors.git" "$repo_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 Installing yazi flavors"* ]]
  [[ "$output" == *"GIT_CLONE: clone git@github.com:yazi-rs/flavors.git"* ]]
  [ -d "$repo_path" ]
}

@test "clone_yazi_flavors handles git clone failure" {
  # Mock git command to fail
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Git clone failed"
      return 1
    else
      command git "$@"
    fi
  }
  
  run clone_yazi_flavors "git@github.com:yazi-rs/flavors.git" "$HOME/Repos/yazi-rs/flavors"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to clone yazi flavors repository"* ]]
}

# Test setup_yazi_theme_symlink
@test "setup_yazi_theme_symlink creates symlink when theme exists" {
  local flavors_path="$HOME/Repos/yazi-rs/flavors"
  local config_dir="$HOME/.config/yazi/flavors"
  local theme="catppuccin-mocha.yazi"
  
  # Create source theme directory
  mkdir -p "$flavors_path/$theme"
  
  # Mock ln command
  ln() {
    if [[ "$1" == "-sfv" ]]; then
      echo "LN_COMMAND: ln $*"
      return 0
    else
      command ln "$@"
    fi
  }
  
  run setup_yazi_theme_symlink "$flavors_path" "$config_dir" "$theme"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LN_COMMAND: ln -sfv $flavors_path/$theme $config_dir"* ]]
  [ -d "$config_dir" ]
}

@test "setup_yazi_theme_symlink fails when theme missing" {
  local flavors_path="$HOME/Repos/yazi-rs/flavors"
  local config_dir="$HOME/.config/yazi/flavors" 
  local theme="nonexistent-theme.yazi"
  
  # Create flavors directory but not the theme
  mkdir -p "$flavors_path"
  
  run setup_yazi_theme_symlink "$flavors_path" "$config_dir" "$theme"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Theme $theme not found in flavors repository"* ]]
}

@test "setup_yazi_theme_symlink handles ln failure" {
  local flavors_path="$HOME/Repos/yazi-rs/flavors"
  local config_dir="$HOME/.config/yazi/flavors"
  local theme="catppuccin-mocha.yazi"
  
  # Create source theme
  mkdir -p "$flavors_path/$theme"
  
  # Mock ln to fail
  ln() {
    if [[ "$1" == "-sfv" ]]; then
      echo "ln failed"
      return 1
    else
      command ln "$@"
    fi
  }
  
  run setup_yazi_theme_symlink "$flavors_path" "$config_dir" "$theme"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to create symlink for yazi theme"* ]]
}

# Test yazi_config_exists
@test "yazi_config_exists returns true when config directory exists" {
  local config_dir="$HOME/.config/yazi"
  mkdir -p "$config_dir"
  
  run yazi_config_exists "$config_dir"
  [ "$status" -eq 0 ]
}

@test "yazi_config_exists returns false when config directory missing" {
  local config_dir="$HOME/.config/yazi"
  
  run yazi_config_exists "$config_dir"
  [ "$status" -ne 0 ]
}

# Test get_yazi_flavors_path
@test "get_yazi_flavors_path returns expected path" {
  run get_yazi_flavors_path
  [ "$status" -eq 0 ]
  [[ "$output" == *"/Repos/yazi-rs/flavors" ]]
}

# Test is_theme_symlinked
@test "is_theme_symlinked returns true when symlink exists" {
  local config_dir="$HOME/.config/yazi/flavors"
  local theme="catppuccin-mocha.yazi"
  
  mkdir -p "$config_dir"
  ln -s "/some/source" "$config_dir/$theme"
  
  run is_theme_symlinked "$theme" "$config_dir"
  [ "$status" -eq 0 ]
}

@test "is_theme_symlinked returns false when symlink missing" {
  local config_dir="$HOME/.config/yazi/flavors"
  local theme="catppuccin-mocha.yazi"
  
  mkdir -p "$config_dir"
  
  run is_theme_symlinked "$theme" "$config_dir"
  [ "$status" -ne 0 ]
}