#!/usr/bin/env bash
set -euo pipefail

# DOCS: https://bats-core.readthedocs.io/en/stable/writing-tests.html

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
# Note: $status and $output are built-in BATS variables
assert_success() {
    # Declare BATS built-in variables for shellcheck
    local status="${status:-}"
    local output="${output:-}"

    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got exit code: $status"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    # Declare BATS built-in variables for shellcheck
    local status="${status:-}"
    local output="${output:-}"

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

# BATS-style assert_output function with --partial support
assert_output() {
    local expected
    local partial=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --partial)
            partial=true
            shift
            ;;
        *)
            expected="$1"
            shift
            ;;
        esac
    done

    if [[ "$partial" == "true" ]]; then
        # Partial match
        if [[ "$output" != *"$expected"* ]]; then
            echo "Expected output to contain: $expected"
            echo "Actual output: $output"
            return 1
        fi
    else
        # Exact match
        if [[ "$output" != "$expected" ]]; then
            echo "Expected output: $expected"
            echo "Actual output: $output"
            return 1
        fi
    fi
}

# BATS-style assert_equal function
assert_equal() {
    local expected="$1"
    local actual="$2"

    if [[ "$actual" != "$expected" ]]; then
        echo "Expected: $expected"
        echo "Actual: $actual"
        return 1
    fi
}

# BATS-style assert_not_equal function
assert_not_equal() {
    local expected="$1"
    local actual="$2"

    if [[ "$actual" == "$expected" ]]; then
        echo "Expected NOT to equal: $expected"
        echo "Actual: $actual"
        return 1
    fi
}
