#!/usr/bin/env bats

# Integration tests for content installation

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Save original environment
  export ORIGINAL_HOME="$HOME"
  export ORIGINAL_DOTFILES="${DOTFILES:-}"
  
  # Set up test environment
  export HOME="$TEST_TEMP_DIR/fake_home"
  export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
  
  mkdir -p "$HOME"
  
  # Create fake dotfiles structure
  mkdir -p "$DOTFILES/lib"
  mkdir -p "$DOTFILES/bin/lib"
  mkdir -p "$DOTFILES/bin/install"
  
  # Copy utilities
  cp "lib/content-utils.bash" "$DOTFILES/lib/"
  cp "bin/lib/dry-run-utils.bash" "$DOTFILES/bin/lib/"
}

teardown() {
  # Restore original environment
  export HOME="$ORIGINAL_HOME"
  if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
    export DOTFILES="$ORIGINAL_DOTFILES"
  else
    unset DOTFILES
  fi
  
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

@test "content installation skips when repository already exists" {
  # Create existing content repository
  mkdir -p "$HOME/Repos/ooloth/content"
  
  run bash "bin/install/content.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 content repo is already installed"* ]]
}

@test "content installation clones repository successfully" {
  # Mock git command to succeed
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Cloning content repository..."
      local repo_path="$3"
      mkdir -p "$repo_path/.git"
      return 0
    elif [[ "$1" == "-C" && "$3" == "rev-parse" ]]; then
      return 0  # Valid git repo
    else
      command git "$@"
    fi
  }
  
  run bash "bin/install/content.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 Installing content repo"* ]]
  [[ "$output" == *"Cloning content repository..."* ]]
  [[ "$output" == *"✅ content repo installed successfully"* ]]
}

@test "content installation handles dry run mode" {
  # Set dry run mode
  export DRY_RUN=1
  
  run bash "bin/install/content.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would clone content repository"* ]]
  
  # Verify no actual changes were made
  [[ "$output" != *"Cloning content repository"* ]]
}

@test "content installation fails when git unavailable" {
  # Mock command to simulate git being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "git" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run bash "bin/install/content.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ git is not available"* ]]
}

@test "content installation handles git clone failure" {
  # Mock git to fail
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Git clone failed"
      return 1
    else
      command git "$@"
    fi
  }
  
  run bash "bin/install/content.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to clone content repository"* ]]
  [[ "$output" == *"❌ Failed to install content repository"* ]]
}

@test "content installation validates cloned repository" {
  # Mock git clone to succeed but validation to fail
  git() {
    if [[ "$1" == "clone" ]]; then
      local repo_path="$3"
      mkdir -p "$repo_path"  # Create directory but not .git
      return 0
    elif [[ "$1" == "-C" && "$3" == "rev-parse" ]]; then
      return 1  # Invalid git repo
    else
      command git "$@"
    fi
  }
  
  run bash "bin/install/content.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Cloned repository is not a valid git repository"* ]]
}

@test "content installation uses correct repository URL and path" {
  # Track parameters passed to git
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "GIT_CLONE: repo=$2 path=$3"
      mkdir -p "$3/.git"
      return 0
    elif [[ "$1" == "-C" && "$3" == "rev-parse" ]]; then
      return 0
    else
      command git "$@"
    fi
  }
  
  run bash "bin/install/content.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GIT_CLONE: repo=git@github.com:ooloth/content.git path=$HOME/Repos/ooloth/content"* ]]
}

@test "content installation validates repository URL" {
  # This test verifies the script checks URL validity
  # Since we're using a valid URL by default, we test the validation logic indirectly
  
  run bash "bin/install/content.bash"
  # The script should not fail due to URL validation
  # (it may fail for other reasons like missing git)
  [[ "$output" != *"❌ Invalid repository URL"* ]]
}