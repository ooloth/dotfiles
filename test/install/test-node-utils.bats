#!/usr/bin/env bats

# Test Node.js utility functions

# Load the Node utilities
load "../../lib/node-utils.bash"

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

@test "fnm_installed returns false when fnm not found" {
    # Ensure fnm is not in PATH
    PATH="$MOCK_BIN"
    
    run fnm_installed
    [ "$status" -eq 1 ]
}