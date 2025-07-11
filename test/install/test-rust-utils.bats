#!/usr/bin/env bats

# Test Rust utility functions

# Load the Rust utilities
load "../../lib/rust-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_CARGO_HOME="${CARGO_HOME:-}"
    export ORIGINAL_RUSTUP_HOME="${RUSTUP_HOME:-}"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    if [[ -n "$ORIGINAL_CARGO_HOME" ]]; then
        export CARGO_HOME="$ORIGINAL_CARGO_HOME"
    else
        unset CARGO_HOME
    fi
    
    if [[ -n "$ORIGINAL_RUSTUP_HOME" ]]; then
        export RUSTUP_HOME="$ORIGINAL_RUSTUP_HOME"
    else
        unset RUSTUP_HOME
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "rust_installed returns false when rustup not found" {
    # Ensure rustup is not in PATH
    PATH="$MOCK_BIN"
    
    run rust_installed
    [ "$status" -eq 1 ]
}