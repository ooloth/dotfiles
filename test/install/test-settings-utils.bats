#!/usr/bin/env bats

# Test suite for settings-utils.bash

# Load the settings utilities
load "../../lib/settings-utils.bash"

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test is_defaults_available
@test "is_defaults_available returns true when defaults command exists" {
  # Mock command to simulate defaults being available
  command() {
    if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_defaults_available
  [ "$status" -eq 0 ]
}

@test "is_defaults_available returns false when defaults command missing" {
  # Mock command to simulate defaults being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_defaults_available
  [ "$status" -ne 0 ]
}

# Test is_chflags_available
@test "is_chflags_available returns true when chflags command exists" {
  # Mock command to simulate chflags being available
  command() {
    if [[ "$1" == "-v" && "$2" == "chflags" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_chflags_available
  [ "$status" -eq 0 ]
}

@test "is_chflags_available returns false when chflags command missing" {
  # Mock command to simulate chflags being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "chflags" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_chflags_available
  [ "$status" -ne 0 ]
}

# Test apply_defaults_setting
@test "apply_defaults_setting executes defaults write command" {
  # Mock defaults command
  defaults() {
    if [[ "$1" == "write" ]]; then
      echo "DEFAULTS_WRITE: domain=$2 key=$3 type=$4 value=$5"
      return 0
    else
      command defaults "$@"
    fi
  }
  
  run apply_defaults_setting "com.test.app" "TestKey" "bool" "true" "Test description"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test description"* ]]
  [[ "$output" == *"DEFAULTS_WRITE: domain=com.test.app key=TestKey type=-bool value=true"* ]]
}

@test "apply_defaults_setting handles defaults command failure" {
  # Mock defaults command to fail
  defaults() {
    if [[ "$1" == "write" ]]; then
      echo "defaults failed"
      return 1
    else
      command defaults "$@"
    fi
  }
  
  run apply_defaults_setting "com.test.app" "TestKey" "bool" "true" "Test description"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to set com.test.app TestKey"* ]]
}

# Test apply_bool_setting
@test "apply_bool_setting calls apply_defaults_setting with bool type" {
  # Mock apply_defaults_setting
  apply_defaults_setting() {
    echo "APPLY_DEFAULTS: domain=$1 key=$2 type=$3 value=$4 desc=$5"
    return 0
  }
  
  run apply_bool_setting "NSGlobalDomain" "TestBool" "true" "Test boolean setting"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APPLY_DEFAULTS: domain=NSGlobalDomain key=TestBool type=bool value=true desc=Test boolean setting"* ]]
}

# Test apply_int_setting
@test "apply_int_setting calls apply_defaults_setting with int type" {
  # Mock apply_defaults_setting
  apply_defaults_setting() {
    echo "APPLY_DEFAULTS: domain=$1 key=$2 type=$3 value=$4 desc=$5"
    return 0
  }
  
  run apply_int_setting "NSGlobalDomain" "TestInt" "42" "Test integer setting"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APPLY_DEFAULTS: domain=NSGlobalDomain key=TestInt type=int value=42 desc=Test integer setting"* ]]
}

# Test apply_string_setting
@test "apply_string_setting calls apply_defaults_setting with string type" {
  # Mock apply_defaults_setting
  apply_defaults_setting() {
    echo "APPLY_DEFAULTS: domain=$1 key=$2 type=$3 value=$4 desc=$5"
    return 0
  }
  
  run apply_string_setting "com.test.app" "TestString" "value" "Test string setting"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APPLY_DEFAULTS: domain=com.test.app key=TestString type=string value=value desc=Test string setting"* ]]
}

# Test configure_general_settings
@test "configure_general_settings applies all general settings" {
  # Mock apply_bool_setting and apply_int_setting
  apply_bool_setting() {
    echo "BOOL_SETTING: $1 $2 = $3"
    return 0
  }
  
  apply_int_setting() {
    echo "INT_SETTING: $1 $2 = $3"
    return 0
  }
  
  run configure_general_settings
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configuring general settings..."* ]]
  [[ "$output" == *"BOOL_SETTING: NSGlobalDomain NSNavPanelExpandedStateForSaveMode = true"* ]]
  [[ "$output" == *"INT_SETTING: NSGlobalDomain AppleKeyboardUIMode = 3"* ]]
  [[ "$output" == *"INT_SETTING: NSGlobalDomain AppleFontSmoothing = 2"* ]]
}

# Test configure_finder_settings
@test "configure_finder_settings applies all finder settings" {
  # Mock apply_bool_setting, apply_string_setting, and chflags
  apply_bool_setting() {
    echo "BOOL_SETTING: $1 $2 = $3"
    return 0
  }
  
  apply_string_setting() {
    echo "STRING_SETTING: $1 $2 = $3"
    return 0
  }
  
  chflags() {
    echo "CHFLAGS: $*"
    return 0
  }
  
  run configure_finder_settings
  [ "$status" -eq 0 ]
  [[ "$output" == *"🔍 Configuring Finder..."* ]]
  [[ "$output" == *"BOOL_SETTING: NSGlobalDomain AppleShowAllExtensions = true"* ]]
  [[ "$output" == *"BOOL_SETTING: com.apple.Finder AppleShowAllFiles = false"* ]]
  [[ "$output" == *"STRING_SETTING: com.apple.finder FXDefaultSearchScope = SCcf"* ]]
  [[ "$output" == *"CHFLAGS: nohidden"* ]]
}

@test "configure_finder_settings handles chflags failure" {
  # Mock settings functions to succeed but chflags to fail
  apply_bool_setting() { return 0; }
  apply_string_setting() { return 0; }
  
  chflags() {
    echo "chflags failed"
    return 1
  }
  
  run configure_finder_settings
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to unhide ~/Library folder"* ]]
}

# Test configure_safari_settings
@test "configure_safari_settings applies safari settings" {
  # Mock apply_bool_setting
  apply_bool_setting() {
    echo "BOOL_SETTING: $1 $2 = $3"
    return 0
  }
  
  run configure_safari_settings
  [ "$status" -eq 0 ]
  [[ "$output" == *"🌐 Configuring Safari..."* ]]
  [[ "$output" == *"BOOL_SETTING: com.apple.Safari IncludeInternalDebugMenu = true"* ]]
}

# Test is_macos
@test "is_macos returns true on Darwin system" {
  # Mock uname to return Darwin
  uname() {
    echo "Darwin"
  }
  
  run is_macos
  [ "$status" -eq 0 ]
}

@test "is_macos returns false on non-Darwin system" {
  # Mock uname to return Linux
  uname() {
    echo "Linux"
  }
  
  run is_macos
  [ "$status" -ne 0 ]
}

# Test validate_macos_environment
@test "validate_macos_environment succeeds when all requirements met" {
  # Mock all required functions to succeed
  is_macos() { return 0; }
  is_defaults_available() { return 0; }
  is_chflags_available() { return 0; }
  
  run validate_macos_environment
  [ "$status" -eq 0 ]
}

@test "validate_macos_environment fails when not on macOS" {
  # Mock is_macos to fail
  is_macos() { return 1; }
  is_defaults_available() { return 0; }
  is_chflags_available() { return 0; }
  
  run validate_macos_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ macOS system settings can only be applied on macOS"* ]]
}

@test "validate_macos_environment fails when defaults unavailable" {
  # Mock defaults to be unavailable
  is_macos() { return 0; }
  is_defaults_available() { return 1; }
  is_chflags_available() { return 0; }
  
  run validate_macos_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ defaults command not available"* ]]
}

@test "validate_macos_environment fails when chflags unavailable" {
  # Mock chflags to be unavailable
  is_macos() { return 0; }
  is_defaults_available() { return 0; }
  is_chflags_available() { return 1; }
  
  run validate_macos_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ chflags command not available"* ]]
}