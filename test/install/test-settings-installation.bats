#!/usr/bin/env bats

# Integration tests for settings installation

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Save original environment
  export ORIGINAL_DOTFILES="${DOTFILES:-}"
  
  # Set up test environment
  export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
  
  # Create fake dotfiles structure
  mkdir -p "$DOTFILES/lib"
  mkdir -p "$DOTFILES/bin/lib"
  mkdir -p "$DOTFILES/bin/install"
  
  # Copy utilities
  cp "lib/settings-utils.bash" "$DOTFILES/lib/"
  cp "bin/lib/dry-run-utils.bash" "$DOTFILES/bin/lib/"
}

teardown() {
  # Restore original environment
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

@test "settings installation runs on macOS with required commands" {
  # Mock all required functions to succeed
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  # Mock settings configuration functions
  configure_general_settings() {
    echo "Configuring general settings..."
    return 0
  }
  
  configure_finder_settings() {
    echo "Configuring Finder settings..."
    return 0
  }
  
  configure_safari_settings() {
    echo "Configuring Safari settings..."
    return 0
  }
  
  run bash "bin/install/settings.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"💻 Configuring macOS system settings"* ]]
  [[ "$output" == *"Configuring general settings..."* ]]
  [[ "$output" == *"Configuring Finder settings..."* ]]
  [[ "$output" == *"Configuring Safari settings..."* ]]
  [[ "$output" == *"🚀 Done configuring Mac system preferences."* ]]
}

@test "settings installation handles dry run mode" {
  # Set dry run mode
  export DRY_RUN=1
  
  # Mock environment validation
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run bash "bin/install/settings.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would configure the following macOS settings:"* ]]
  [[ "$output" == *"General Settings:"* ]]
  [[ "$output" == *"Finder Settings:"* ]]
  [[ "$output" == *"Safari Settings:"* ]]
  
  # Verify no actual configuration was attempted
  [[ "$output" != *"Configuring general settings..."* ]]
}

@test "settings installation fails on non-macOS systems" {
  # Mock uname to return non-Darwin
  uname() { echo "Linux"; }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ macOS system settings can only be applied on macOS"* ]]
}

@test "settings installation fails when defaults command unavailable" {
  # Mock macOS but missing defaults command
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
      return 1
    elif [[ "$1" == "-v" && "$2" == "chflags" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ defaults command not available"* ]]
}

@test "settings installation fails when chflags command unavailable" {
  # Mock macOS but missing chflags command
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
      return 0
    elif [[ "$1" == "-v" && "$2" == "chflags" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ chflags command not available"* ]]
}

@test "settings installation handles general settings failure" {
  # Mock environment validation to succeed
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  # Mock configure_general_settings to fail
  configure_general_settings() {
    echo "General settings failed"
    return 1
  }
  
  configure_finder_settings() { return 0; }
  configure_safari_settings() { return 0; }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure general settings"* ]]
}

@test "settings installation handles finder settings failure" {
  # Mock environment validation to succeed
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  # Mock configure_finder_settings to fail
  configure_general_settings() { return 0; }
  configure_finder_settings() {
    echo "Finder settings failed"
    return 1
  }
  configure_safari_settings() { return 0; }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure Finder settings"* ]]
}

@test "settings installation handles safari settings failure" {
  # Mock environment validation to succeed
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  # Mock configure_safari_settings to fail
  configure_general_settings() { return 0; }
  configure_finder_settings() { return 0; }
  configure_safari_settings() {
    echo "Safari settings failed"
    return 1
  }
  
  run bash "bin/install/settings.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure Safari settings"* ]]
}