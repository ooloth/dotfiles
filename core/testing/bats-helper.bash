#!/usr/bin/env bash

# BATS test helper functions for feature tests
# Provides common utilities and setup for core/ and features/ tests

set -euo pipefail

# Setup test environment
setup_test_env() {
    # Create temporary directory for test
    if [[ -z "${TEST_TEMP_DIR:-}" ]]; then
        export TEST_TEMP_DIR
        TEST_TEMP_DIR="$(mktemp -d)"
    fi
    
    # Save original environment
    export ORIGINAL_HOME="${HOME:-}"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set up isolated test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    # Create basic directory structure
    mkdir -p "$HOME"
    mkdir -p "$DOTFILES"
}

# Cleanup test environment
cleanup_test_env() {
    # Restore original environment
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
    
    if [[ -n "${ORIGINAL_DOTFILES:-}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        unset TEST_TEMP_DIR
    fi
}

# Mock command function
mock_command() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    
    eval "$cmd() { 
        if [[ -n '$output' ]]; then
            echo '$output'
        fi
        return $exit_code
    }"
}

# Assert helpers for BATS
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got exit code: $status"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure but got success"
        echo "Output: $output"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_output_not_contains() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}