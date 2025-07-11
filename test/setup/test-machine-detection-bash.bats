#!/usr/bin/env bats

# Machine detection utility tests (bash version)
# Tests the bash version of machine detection functionality

# Load the machine detection utilities
load "../../bin/lib/machine-detection.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_MACHINE="${MACHINE:-}"
    export ORIGINAL_HOST="${HOST:-}"
    
    # Clear machine-related environment variables for clean testing
    unset MACHINE IS_AIR IS_MINI IS_WORK
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export PATH="$ORIGINAL_PATH"
    if [[ -n "$ORIGINAL_MACHINE" ]]; then
        export MACHINE="$ORIGINAL_MACHINE"
    else
        unset MACHINE
    fi
    if [[ -n "$ORIGINAL_HOST" ]]; then
        export HOST="$ORIGINAL_HOST"
    else
        unset HOST
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    # Clean up any machine variables set during tests
    unset IS_AIR IS_MINI IS_WORK
}

# Unit Tests for detect_machine_type function

@test "detect_machine_type returns air for hostname containing Air" {
    # Create fake hostname command
    echo '#!/bin/bash
echo "MacBook-Air-2023"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "air" ]
}

@test "detect_machine_type returns mini for hostname containing Mini" {
    # Create fake hostname command  
    echo '#!/bin/bash
echo "Mac-Mini-Server"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "mini" ]
}

@test "detect_machine_type returns work for other hostnames" {
    # Create fake hostname command
    echo '#!/bin/bash
echo "MacBook-Pro-Work"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "work" ]
}

@test "detect_machine_type uses MACHINE environment variable when set" {
    export MACHINE="air"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "air" ]
}

@test "detect_machine_type falls back to HOST when hostname unavailable" {
    # Create an empty directory and use only that in PATH
    mkdir -p "$TEST_TEMP_DIR/empty"
    export PATH="$TEST_TEMP_DIR/empty"
    export HOST="Mini-Test-Host"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "mini" ]
}

@test "detect_machine_type defaults to work for unknown hostname" {
    # Create fake hostname command with unknown hostname
    echo '#!/bin/bash
echo "unknown-machine"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run detect_machine_type
    [ "$status" -eq 0 ]
    [ "$output" = "work" ]
}

# Unit Tests for set_machine_variables function

@test "set_machine_variables sets IS_AIR=true for air machine type" {
    # Function sets variables in current shell, don't use run
    set_machine_variables "air"
    
    # Check that variables are set correctly
    [ "$IS_AIR" = "true" ]
    [ "$IS_MINI" = "false" ]
    [ "$IS_WORK" = "false" ]
    [ "$MACHINE" = "air" ]
}

@test "set_machine_variables sets IS_MINI=true for mini machine type" {
    # Function sets variables in current shell, don't use run
    set_machine_variables "mini"
    
    # Check that variables are set correctly
    [ "$IS_AIR" = "false" ]
    [ "$IS_MINI" = "true" ]
    [ "$IS_WORK" = "false" ]
    [ "$MACHINE" = "mini" ]
}

@test "set_machine_variables sets IS_WORK=true for work machine type" {
    # Function sets variables in current shell, don't use run
    set_machine_variables "work"
    
    # Check that variables are set correctly
    [ "$IS_AIR" = "false" ]
    [ "$IS_MINI" = "false" ]
    [ "$IS_WORK" = "true" ]
    [ "$MACHINE" = "work" ]
}

@test "set_machine_variables defaults to work for unknown machine type" {
    # Function sets variables in current shell, don't use run
    set_machine_variables "unknown"
    
    # Check that variables are set correctly
    [ "$IS_AIR" = "false" ]
    [ "$IS_MINI" = "false" ]
    [ "$IS_WORK" = "true" ]
    [ "$MACHINE" = "work" ]
}

# Unit Tests for init_machine_detection function

@test "init_machine_detection detects and sets variables correctly" {
    # Create fake hostname command
    echo '#!/bin/bash
echo "MacBook-Air-Personal"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Function sets variables in current shell, don't use run
    init_machine_detection
    
    # Check that detection worked and variables are set
    [ "$MACHINE" = "air" ]
    [ "$IS_AIR" = "true" ]
    [ "$IS_MINI" = "false" ]
    [ "$IS_WORK" = "false" ]
}

@test "init_machine_detection with debug mode prints detection result" {
    # Create fake hostname command
    echo '#!/bin/bash
echo "Mini-Server"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    export DEBUG_MACHINE_DETECTION="true"
    
    run init_machine_detection
    [ "$status" -eq 0 ]
    [[ "$output" == *"Detected machine type: mini"* ]]
}

@test "init_machine_detection without debug mode produces no output" {
    # Create fake hostname command
    echo '#!/bin/bash
echo "MacBook-Pro-Work"' > "$TEST_TEMP_DIR/hostname"
    chmod +x "$TEST_TEMP_DIR/hostname"
    export PATH="$TEST_TEMP_DIR:$PATH"
    export DEBUG_MACHINE_DETECTION="false"
    
    run init_machine_detection
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}