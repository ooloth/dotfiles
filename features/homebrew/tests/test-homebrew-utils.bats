#!/usr/bin/env bats

# Homebrew utility functions tests
# Tests the core Homebrew detection and validation functions
# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"

# Load the Homebrew utilities
load "../utils.bash"

# Test setup and teardown
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original HOME and PATH for restoration
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_PATH="$PATH"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Unit Tests for get_homebrew_prefix function

@test "get_homebrew_prefix returns /opt/homebrew on Apple Silicon" {
    # Create a fake uname command that returns arm64
    echo '#!/bin/bash
echo "arm64"' > "$TEST_TEMP_DIR/uname"
    chmod +x "$TEST_TEMP_DIR/uname"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run get_homebrew_prefix
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/homebrew" ]
}

@test "get_homebrew_prefix returns /usr/local on Intel" {
    # Create a fake uname command that returns x86_64
    echo '#!/bin/bash
echo "x86_64"' > "$TEST_TEMP_DIR/uname"
    chmod +x "$TEST_TEMP_DIR/uname"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run get_homebrew_prefix
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local" ]
}

@test "get_homebrew_prefix returns /usr/local for unknown architecture" {
    # Create a fake uname command that returns unknown value
    echo '#!/bin/bash
echo "unknown"' > "$TEST_TEMP_DIR/uname"
    chmod +x "$TEST_TEMP_DIR/uname"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run get_homebrew_prefix
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local" ]
}

# Unit Tests for ensure_homebrew_in_path function

@test "ensure_homebrew_in_path adds homebrew prefix to PATH when missing" {
    # Create a fake uname command that returns arm64
    echo '#!/bin/bash
echo "arm64"' > "$TEST_TEMP_DIR/uname"
    chmod +x "$TEST_TEMP_DIR/uname"
    export PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Function modifies PATH, so we need to source and check in same shell
    ensure_homebrew_in_path
    [ "$?" -eq 0 ]
    # Check that /opt/homebrew/bin is now in PATH
    [[ "$PATH" == *"/opt/homebrew/bin"* ]]
}

@test "ensure_homebrew_in_path does not duplicate when already in PATH" {
    # Create a fake uname command that returns arm64
    echo '#!/bin/bash
echo "arm64"' > "$TEST_TEMP_DIR/uname"
    chmod +x "$TEST_TEMP_DIR/uname"
    export PATH="/opt/homebrew/bin:$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run ensure_homebrew_in_path
    [ "$status" -eq 0 ]
    # Check that PATH doesn't have duplicate entries
    local path_count=$(echo "$PATH" | tr ':' '\n' | grep -c "/opt/homebrew/bin")
    [ "$path_count" -eq 1 ]
}

# Unit Tests for is_homebrew_package_installed function

@test "is_homebrew_package_installed returns 0 when package is installed" {
    # Create a fake brew command that lists packages including git
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "--formula" ]]; then
    echo "git"
    echo "node"
    echo "python@3.11"
fi' > "$TEST_TEMP_DIR/brew"
    chmod +x "$TEST_TEMP_DIR/brew"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_homebrew_package_installed "git"
    [ "$status" -eq 0 ]
}

@test "is_homebrew_package_installed returns 1 when package is not installed" {
    # Create a fake brew command that lists packages NOT including git
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "--formula" ]]; then
    echo "node"
    echo "python@3.11"
fi' > "$TEST_TEMP_DIR/brew"
    chmod +x "$TEST_TEMP_DIR/brew"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_homebrew_package_installed "git"
    [ "$status" -eq 1 ]
}

@test "is_homebrew_package_installed returns 1 when brew list fails" {
    # Create a fake brew command that fails
    echo '#!/bin/bash
echo "Error: No such command" >&2
exit 1' > "$TEST_TEMP_DIR/brew"
    chmod +x "$TEST_TEMP_DIR/brew"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_homebrew_package_installed "git"
    [ "$status" -eq 1 ]
}

@test "is_homebrew_package_installed requires package name argument" {
    run is_homebrew_package_installed ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Package name is required"* ]]
}