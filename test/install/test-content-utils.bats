#!/usr/bin/env bats

# Test suite for content-utils.bash

# Load the content utilities
load "../../lib/content-utils.bash"

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

# Test is_content_repo_installed
@test "is_content_repo_installed returns true when repository exists" {
  local repo_path="$HOME/Repos/ooloth/content"
  mkdir -p "$repo_path"
  
  run is_content_repo_installed "$repo_path"
  [ "$status" -eq 0 ]
}

@test "is_content_repo_installed returns false when repository missing" {
  local repo_path="$HOME/Repos/ooloth/content"
  
  run is_content_repo_installed "$repo_path"
  [ "$status" -ne 0 ]
}

@test "is_content_repo_installed uses default path when not specified" {
  mkdir -p "$HOME/Repos/ooloth/content"
  
  run is_content_repo_installed
  [ "$status" -eq 0 ]
}

# Test clone_content_repo
@test "clone_content_repo creates directory and runs git clone" {
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
  
  local repo_path="$HOME/Repos/ooloth/content"
  
  run clone_content_repo "git@github.com:ooloth/content.git" "$repo_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 Installing content repo"* ]]
  [[ "$output" == *"GIT_CLONE: clone git@github.com:ooloth/content.git"* ]]
  [ -d "$repo_path" ]
}

@test "clone_content_repo handles git clone failure" {
  # Mock git command to fail
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Git clone failed"
      return 1
    else
      command git "$@"
    fi
  }
  
  run clone_content_repo "git@github.com:ooloth/content.git" "$HOME/Repos/ooloth/content"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to clone content repository"* ]]
}

@test "clone_content_repo uses default parameters" {
  # Mock git command
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "GIT_CLONE: repo=$2 path=$3"
      mkdir -p "$3"
      return 0
    else
      command git "$@"
    fi
  }
  
  run clone_content_repo
  [ "$status" -eq 0 ]
  [[ "$output" == *"GIT_CLONE: repo=git@github.com:ooloth/content.git path=$HOME/Repos/ooloth/content"* ]]
}

# Test get_content_repo_path
@test "get_content_repo_path returns expected path" {
  run get_content_repo_path
  [ "$status" -eq 0 ]
  [[ "$output" == *"/Repos/ooloth/content" ]]
}

# Test is_git_available
@test "is_git_available returns true when git command exists" {
  # Mock command to simulate git being available
  command() {
    if [[ "$1" == "-v" && "$2" == "git" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_git_available
  [ "$status" -eq 0 ]
}

@test "is_git_available returns false when git command missing" {
  # Mock command to simulate git being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "git" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_git_available
  [ "$status" -ne 0 ]
}

# Test is_valid_repo_url
@test "is_valid_repo_url accepts SSH URLs" {
  run is_valid_repo_url "git@github.com:ooloth/content.git"
  [ "$status" -eq 0 ]
}

@test "is_valid_repo_url accepts HTTPS URLs" {
  run is_valid_repo_url "https://github.com/ooloth/content.git"
  [ "$status" -eq 0 ]
}

@test "is_valid_repo_url rejects invalid URLs" {
  run is_valid_repo_url "invalid-url"
  [ "$status" -ne 0 ]
}

@test "is_valid_repo_url rejects URLs without domain" {
  run is_valid_repo_url "git@repo"
  [ "$status" -ne 0 ]
}

# Test is_valid_git_repo
@test "is_valid_git_repo returns true for directory with .git" {
  local repo_path="$HOME/test_repo"
  mkdir -p "$repo_path/.git"
  
  run is_valid_git_repo "$repo_path"
  [ "$status" -eq 0 ]
}

@test "is_valid_git_repo returns false for non-git directory" {
  local repo_path="$HOME/test_repo"
  mkdir -p "$repo_path"
  
  # Mock git command to fail
  git() {
    return 1
  }
  
  run is_valid_git_repo "$repo_path"
  [ "$status" -ne 0 ]
}

@test "is_valid_git_repo uses git command as fallback" {
  local repo_path="$HOME/test_repo"
  mkdir -p "$repo_path"
  
  # Mock git command to succeed
  git() {
    if [[ "$1" == "-C" && "$3" == "rev-parse" ]]; then
      return 0
    else
      command git "$@"
    fi
  }
  
  run is_valid_git_repo "$repo_path"
  [ "$status" -eq 0 ]
}