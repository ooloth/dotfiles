#!/usr/bin/env bats

# Prerequisite validation utility tests (bash version)
# Tests the bash version of prerequisite validation functionality

# Load the prerequisite validation utilities
load "../validation.bash"
load "../../testing/bats-helper.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"

    # Save original environment
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

# Unit Tests for validate_command_line_tools function

@test "validate_command_line_tools passes when xcode-select works and tools exist" {
    # Create fake xcode-select that returns a valid path
    echo '#!/bin/bash
if [[ "$1" == "-p" ]]; then
    echo "'"$TEST_TEMP_DIR"'/Developer"
fi' >"$TEST_TEMP_DIR/xcode-select"
    chmod +x "$TEST_TEMP_DIR/xcode-select"

    # Create fake developer directory structure
    mkdir -p "$TEST_TEMP_DIR/Developer/usr/bin"
    touch "$TEST_TEMP_DIR/Developer/usr/bin/git"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_command_line_tools
    [ "$status" -eq 0 ]
}

@test "validate_command_line_tools fails when xcode-select fails" {
    # Create fake xcode-select that fails
    echo '#!/bin/bash
exit 1' >"$TEST_TEMP_DIR/xcode-select"
    chmod +x "$TEST_TEMP_DIR/xcode-select"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_command_line_tools
    [ "$status" -eq 1 ]
    [[ "$output" == *"Command Line Tools not found"* ]]
}

@test "validate_command_line_tools fails when directory exists but git missing" {
    # Create fake xcode-select that returns a path
    echo '#!/bin/bash
if [[ "$1" == "-p" ]]; then
    echo "'"$TEST_TEMP_DIR"'/Developer"
fi' >"$TEST_TEMP_DIR/xcode-select"
    chmod +x "$TEST_TEMP_DIR/xcode-select"

    # Create directory but don't include git
    mkdir -p "$TEST_TEMP_DIR/Developer/usr/bin"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_command_line_tools
    [ "$status" -eq 1 ]
    [[ "$output" == *"appears incomplete"* ]]
}

# Unit Tests for validate_network_connectivity function

@test "validate_network_connectivity passes when all hosts are reachable" {
    # Create fake ping that always succeeds
    echo '#!/bin/bash
exit 0' >"$TEST_TEMP_DIR/ping"
    chmod +x "$TEST_TEMP_DIR/ping"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_network_connectivity
    [ "$status" -eq 0 ]
}

@test "validate_network_connectivity fails when github.com unreachable" {
    # Create fake ping that fails for github.com
    echo '#!/bin/bash
if [[ "$*" == *"github.com"* ]]; then
    exit 1
else
    exit 0
fi' >"$TEST_TEMP_DIR/ping"
    chmod +x "$TEST_TEMP_DIR/ping"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_network_connectivity
    [ "$status" -eq 1 ]
    [[ "$output" == *"Network connectivity failed"* ]]
    [[ "$output" == *"github.com"* ]]
}

@test "validate_network_connectivity fails when all hosts unreachable" {
    # Create fake ping that always fails
    echo '#!/bin/bash
exit 1' >"$TEST_TEMP_DIR/ping"
    chmod +x "$TEST_TEMP_DIR/ping"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_network_connectivity
    [ "$status" -eq 1 ]
    [[ "$output" == *"github.com"* ]]
    [[ "$output" == *"raw.githubusercontent.com"* ]]
}

# Unit Tests for validate_directory_permissions function

@test "validate_directory_permissions passes for existing directory" {
    mkdir -p "$TEST_TEMP_DIR/test_dir"

    run validate_directory_permissions "$TEST_TEMP_DIR/test_dir"
    [ "$status" -eq 0 ]
}

@test "validate_directory_permissions fails for non-existent directory" {
    run validate_directory_permissions "$TEST_TEMP_DIR/nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory does not exist"* ]]
}

@test "validate_directory_permissions fails when no directory provided" {
    run validate_directory_permissions ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory path is required"* ]]
}

# Unit Tests for validate_write_permissions function

@test "validate_write_permissions passes for writable directory" {
    mkdir -p "$TEST_TEMP_DIR/writable"

    run validate_write_permissions "$TEST_TEMP_DIR/writable"
    [ "$status" -eq 0 ]
}

@test "validate_write_permissions fails for non-existent directory" {
    run validate_write_permissions "$TEST_TEMP_DIR/nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory does not exist"* ]]
}

@test "validate_write_permissions fails when no directory provided" {
    run validate_write_permissions ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory path is required"* ]]
}

# Unit Tests for validate_macos_version function

@test "validate_macos_version passes for supported version" {
    # Create fake sw_vers that returns a supported version
    echo '#!/bin/bash
if [[ "$1" == "-productVersion" ]]; then
    echo "14.0"
fi' >"$TEST_TEMP_DIR/sw_vers"
    chmod +x "$TEST_TEMP_DIR/sw_vers"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_macos_version
    [ "$status" -eq 0 ]
}

@test "validate_macos_version fails for unsupported version" {
    # Create fake sw_vers that returns an old version
    echo '#!/bin/bash
if [[ "$1" == "-productVersion" ]]; then
    echo "10.15"
fi' >"$TEST_TEMP_DIR/sw_vers"
    chmod +x "$TEST_TEMP_DIR/sw_vers"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run validate_macos_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unsupported macOS version"* ]]
    [[ "$output" == *"10.15"* ]]
}

@test "validate_macos_version fails when sw_vers unavailable" {
    # Create empty directory first with full PATH
    mkdir -p "$TEST_TEMP_DIR/empty"
    # Then use empty PATH to make sw_vers unavailable
    export PATH="$TEST_TEMP_DIR/empty"

    run validate_macos_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unable to determine macOS version"* ]]
}

# Unit Tests for validate_essential_directories function

@test "validate_essential_directories passes when all directories exist" {
    # Create fake HOME directory
    mkdir -p "$TEST_TEMP_DIR/home"
    export HOME="$TEST_TEMP_DIR/home"

    run validate_essential_directories
    [ "$status" -eq 0 ]
}

@test "validate_essential_directories fails when HOME does not exist" {
    # Set HOME to non-existent directory
    export HOME="$TEST_TEMP_DIR/nonexistent_home"

    run validate_essential_directories
    [ "$status" -eq 1 ]
    [[ "$output" == *"Essential directory validation failed"* ]]
}

# Unit Tests for run_prerequisite_validation function

@test "run_prerequisite_validation passes when all checks pass" {
    # Set up environment for successful validation
    mkdir -p "$TEST_TEMP_DIR/home"
    export HOME="$TEST_TEMP_DIR/home"

    # Create fake commands that succeed
    echo '#!/bin/bash
if [[ "$1" == "-p" ]]; then
    echo "'"$TEST_TEMP_DIR"'/Developer"
fi' >"$TEST_TEMP_DIR/xcode-select"

    echo '#!/bin/bash
exit 0' >"$TEST_TEMP_DIR/ping"

    echo '#!/bin/bash
if [[ "$1" == "-productVersion" ]]; then
    echo "14.0"
fi' >"$TEST_TEMP_DIR/sw_vers"

    chmod +x "$TEST_TEMP_DIR/xcode-select" "$TEST_TEMP_DIR/ping" "$TEST_TEMP_DIR/sw_vers"

    # Create developer directory structure
    mkdir -p "$TEST_TEMP_DIR/Developer/usr/bin"
    touch "$TEST_TEMP_DIR/Developer/usr/bin/git"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run run_prerequisite_validation
    [ "$status" -eq 0 ]
    [[ "$output" == *"All prerequisite validation checks passed"* ]]
}

@test "run_prerequisite_validation fails when any check fails" {
    # Set up environment for failed validation (missing tools)
    mkdir -p "$TEST_TEMP_DIR/home"
    export HOME="$TEST_TEMP_DIR/home"

    # Create fake xcode-select that fails
    echo '#!/bin/bash
exit 1' >"$TEST_TEMP_DIR/xcode-select"
    chmod +x "$TEST_TEMP_DIR/xcode-select"

    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"

    run run_prerequisite_validation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Prerequisite validation failed"* ]]
}

