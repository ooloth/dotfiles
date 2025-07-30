#!/usr/bin/env bats

# Unit tests for settings utility functions

# Load test helpers and utils
load "../../../core/testing/bats-helper.bash"
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Mock macOS environment
    export OSTYPE="darwin21"
}

teardown() {
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "is_macos detects macOS correctly" {
    export OSTYPE="darwin21"
    
    run is_macos
    assert_success
}

@test "is_macos returns false on non-macOS" {
    export OSTYPE="linux-gnu"
    
    run is_macos
    assert_failure
}

@test "is_defaults_available detects defaults command" {
    # Mock defaults command
    defaults() { return 0; }
    export -f defaults
    
    run is_defaults_available
    assert_success
}

@test "is_defaults_available returns false when command missing" {
    # Remove defaults from PATH
    export PATH="/usr/bin:/bin"
    
    run is_defaults_available
    assert_failure
}

@test "is_chflags_available detects chflags command" {
    # Mock chflags command
    chflags() { return 0; }
    export -f chflags
    
    run is_chflags_available
    assert_success
}

@test "is_chflags_available returns false when command missing" {
    # Remove chflags from PATH
    export PATH="/usr/bin:/bin"
    
    run is_chflags_available
    assert_failure
}

@test "validate_macos_settings_environment passes with all commands" {
    # Mock required commands
    defaults() { return 0; }
    chflags() { return 0; }
    export -f defaults chflags
    
    run validate_macos_settings_environment
    assert_success
}

@test "validate_macos_settings_environment fails on non-macOS" {
    export OSTYPE="linux-gnu"
    
    run validate_macos_settings_environment
    assert_failure
}