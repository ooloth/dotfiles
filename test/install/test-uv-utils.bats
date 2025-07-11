#!/usr/bin/env bats

# Test UV utility functions

# Load the UV utilities
load "../../lib/uv-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "uv_installed returns false when uv not found" {
    # Ensure uv is not in PATH
    PATH="$MOCK_BIN"
    
    run uv_installed
    [ "$status" -eq 1 ]
}