#!/usr/bin/env bats

# Test Tmux utility functions

# Load the Tmux utilities
load "../../lib/tmux-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    
    # Set test HOME
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "tpm_installed returns false when TPM not found" {
    run tpm_installed
    [ "$status" -eq 1 ]
}