#!/usr/bin/env bats

# Integration tests for yazi installation

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
  cp "lib/yazi-utils.bash" "$DOTFILES/lib/"
  cp "bin/lib/machine-detection.bash" "$DOTFILES/bin/lib/"
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

@test "yazi installation skips on work machine" {
  # Set work machine environment
  export IS_WORK=true
  
  run bash "bin/install/yazi.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"⏭️  Skipping yazi flavors installation on work machine"* ]]
}

@test "yazi installation skips when already installed" {
  # Set non-work machine
  export IS_WORK=false
  
  # Create existing flavors repository
  mkdir -p "$HOME/Repos/yazi-rs/flavors"
  
  run bash "bin/install/yazi.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 yazi flavors are already installed"* ]]
}

@test "yazi installation clones repository and creates symlink" {
  # Set non-work machine
  export IS_WORK=false
  
  # Mock git command
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Cloning yazi flavors..."
      local repo_path="$3"
      mkdir -p "$repo_path/catppuccin-mocha.yazi"
      return 0
    else
      command git "$@"
    fi
  }
  
  # Mock ln command
  ln() {
    if [[ "$1" == "-sfv" ]]; then
      echo "Creating symlink: $*"
      return 0
    else
      command ln "$@"
    fi
  }
  
  run bash "bin/install/yazi.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📂 Installing yazi flavors"* ]]
  [[ "$output" == *"Cloning yazi flavors..."* ]]
  [[ "$output" == *"Creating symlink:"* ]]
  [[ "$output" == *"✅ yazi flavors installed successfully"* ]]
}

@test "yazi installation handles dry run mode" {
  # Set dry run mode and non-work machine
  export DRY_RUN=1
  export IS_WORK=false
  
  run bash "bin/install/yazi.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would clone yazi flavors repository"* ]]
  [[ "$output" == *"[DRY RUN] Would create symlink for catppuccin-mocha.yazi theme"* ]]
  
  # Verify no actual changes were made
  [[ "$output" != *"Cloning yazi flavors"* ]]
}

@test "yazi installation handles git clone failure" {
  # Set non-work machine
  export IS_WORK=false
  
  # Mock git to fail
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "Git clone failed"
      return 1
    else
      command git "$@"
    fi
  }
  
  run bash "bin/install/yazi.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to clone yazi flavors repository"* ]]
  [[ "$output" == *"❌ Failed to install yazi flavors"* ]]
}

@test "yazi installation handles symlink failure" {
  # Set non-work machine
  export IS_WORK=false
  
  # Mock git to succeed
  git() {
    if [[ "$1" == "clone" ]]; then
      local repo_path="$3"
      mkdir -p "$repo_path/catppuccin-mocha.yazi"
      return 0
    else
      command git "$@"
    fi
  }
  
  # Mock ln to fail
  ln() {
    if [[ "$1" == "-sfv" ]]; then
      echo "ln failed"
      return 1
    else
      command ln "$@"
    fi
  }
  
  run bash "bin/install/yazi.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to create symlink for yazi theme"* ]]
  [[ "$output" == *"❌ Failed to set up yazi theme symlink"* ]]
}

@test "yazi installation uses correct paths and configuration" {
  # Set non-work machine
  export IS_WORK=false
  
  # Track parameters passed to functions
  git() {
    if [[ "$1" == "clone" ]]; then
      echo "GIT_CLONE: repo=$2 path=$3"
      mkdir -p "$3/catppuccin-mocha.yazi"
      return 0
    else
      command git "$@"
    fi
  }
  
  ln() {
    if [[ "$1" == "-sfv" ]]; then
      echo "LN_SYMLINK: source=$2 target=$3"
      return 0
    else
      command ln "$@"
    fi
  }
  
  run bash "bin/install/yazi.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GIT_CLONE: repo=git@github.com:yazi-rs/flavors.git path=$HOME/Repos/yazi-rs/flavors"* ]]
  [[ "$output" == *"LN_SYMLINK: source=$HOME/Repos/yazi-rs/flavors/catppuccin-mocha.yazi target=$HOME/.config/yazi/flavors"* ]]
}