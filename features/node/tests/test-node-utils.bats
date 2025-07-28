#!/usr/bin/env bats

# Node.js utility functions tests
# Tests the core Node.js and fnm utility functions

# Load the Node.js utilities
load "../utils.bash"

# Test setup and teardown
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original PATH for restoration
    export ORIGINAL_PATH="$PATH"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Unit Tests for validate_fnm_installation function

@test "validate_fnm_installation returns 0 when fnm is functional" {
    # Create a fake fnm command that works
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "fnm 1.35.1"
    exit 0
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run validate_fnm_installation
    [ "$status" -eq 0 ]
    [[ "$output" == *"fnm installation is functional"* ]]
}

@test "validate_fnm_installation returns 1 when fnm is not found" {
    # Ensure fnm is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run validate_fnm_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm binary not found"* ]]
}

@test "validate_fnm_installation returns 1 when fnm is not functional" {
    # Create a fake fnm command that fails
    echo '#!/bin/bash
echo "Error: command failed" >&2
exit 1' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run validate_fnm_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm binary found but not functional"* ]]
}

# Unit Tests for get_latest_node_version function

@test "get_latest_node_version returns latest version when available" {
    # Create a fake fnm command that returns version list
    echo '#!/bin/bash
if [[ "$1" == "ls-remote" ]]; then
    echo "v18.18.0"
    echo "v20.10.0"
    echo "v21.1.0"
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run get_latest_node_version
    [ "$status" -eq 0 ]
    [ "$output" = "v21.1.0" ]
}

@test "get_latest_node_version returns 1 when fnm not available" {
    # Ensure fnm is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run get_latest_node_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm not available"* ]]
}

@test "get_latest_node_version returns 1 when fnm ls-remote fails" {
    # Create a fake fnm command that fails on ls-remote
    echo '#!/bin/bash
if [[ "$1" == "ls-remote" ]]; then
    echo "Error: network unavailable" >&2
    exit 1
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run get_latest_node_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to get latest Node.js version"* ]]
}

# Unit Tests for is_node_version_installed function

@test "is_node_version_installed returns 0 when version is installed" {
    # Create a fake fnm command that lists installed versions
    echo '#!/bin/bash
if [[ "$1" == "ls" ]]; then
    echo "v18.18.0"
    echo "v20.10.0"
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run is_node_version_installed "v20.10.0"
    [ "$status" -eq 0 ]
}

@test "is_node_version_installed returns 1 when version is not installed" {
    # Create a fake fnm command that lists installed versions
    echo '#!/bin/bash
if [[ "$1" == "ls" ]]; then
    echo "v18.18.0"
    echo "v20.10.0"
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run is_node_version_installed "v21.1.0"
    [ "$status" -eq 1 ]
}

@test "is_node_version_installed returns 1 when no version provided" {
    run is_node_version_installed ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Node.js version is required"* ]]
}

@test "is_node_version_installed returns 1 when fnm not available" {
    # Ensure fnm is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run is_node_version_installed "v20.10.0"
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm not available"* ]]
}

# Unit Tests for install_node_version function

@test "install_node_version returns 0 when installation succeeds" {
    # Create a fake fnm command that succeeds on install
    echo '#!/bin/bash
if [[ "$1" == "install" && "$2" == "v20.10.0" && "$3" == "--corepack-enabled" ]]; then
    exit 0
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run install_node_version "v20.10.0"
    [ "$status" -eq 0 ]
}

@test "install_node_version returns 1 when installation fails" {
    # Create a fake fnm command that fails on install
    echo '#!/bin/bash
if [[ "$1" == "install" ]]; then
    echo "Error: failed to install" >&2
    exit 1
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run install_node_version "v20.10.0"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install Node.js v20.10.0"* ]]
}

@test "install_node_version returns 1 when no version provided" {
    run install_node_version ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Node.js version is required"* ]]
}

# Unit Tests for set_default_node_version function

@test "set_default_node_version returns 0 when setting default succeeds" {
    # Create a fake fnm command that succeeds on default
    echo '#!/bin/bash
if [[ "$1" == "default" && "$2" == "v20.10.0" ]]; then
    exit 0
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run set_default_node_version "v20.10.0"
    [ "$status" -eq 0 ]
}

@test "set_default_node_version returns 1 when setting default fails" {
    # Create a fake fnm command that fails on default
    echo '#!/bin/bash
if [[ "$1" == "default" ]]; then
    echo "Error: version not found" >&2
    exit 1
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run set_default_node_version "v20.10.0"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to set Node.js v20.10.0 as default"* ]]
}

# Unit Tests for validate_node_installation function

@test "validate_node_installation returns 0 when node is functional" {
    # Create a fake node command that works
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v20.10.0"
    exit 0
fi' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run validate_node_installation
    [ "$status" -eq 0 ]
    [[ "$output" == *"Node.js is functional: v20.10.0"* ]]
}

@test "validate_node_installation returns 1 when node is not found" {
    # Ensure node is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run validate_node_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Node.js binary not found"* ]]
}

@test "validate_node_installation returns 1 when node is not functional" {
    # Create a fake node command that fails
    echo '#!/bin/bash
echo "Error: command failed" >&2
exit 1' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run validate_node_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Node.js binary found but not functional"* ]]
}

# Unit Tests for get_current_node_version function

@test "get_current_node_version returns version when node is available" {
    # Create a fake node command that returns version
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v20.10.0"
    exit 0
fi' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run get_current_node_version
    [ "$status" -eq 0 ]
    [ "$output" = "v20.10.0" ]
}

@test "get_current_node_version returns 1 when node is not available" {
    # Ensure node is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run get_current_node_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"No active Node.js version"* ]]
}

# Unit Tests for get_fnm_version function

@test "get_fnm_version returns version when fnm is available" {
    # Create a fake fnm command that returns version
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "fnm 1.35.1"
    exit 0
fi' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    run get_fnm_version
    [ "$status" -eq 0 ]
    [ "$output" = "fnm 1.35.1" ]
}

@test "get_fnm_version returns message when fnm is not available" {
    # Ensure fnm is not in PATH
    export PATH="/nonexistent:$PATH"
    
    run get_fnm_version
    [ "$status" -eq 1 ]
    [ "$output" = "fnm not available" ]
}