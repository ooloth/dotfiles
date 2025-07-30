#!/usr/bin/env bats

# Unit tests for content utility functions

# Load test helpers and utils
load "../../../core/testing/bats-helper.bash"
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    
    # Set up test environment with fake home
    export HOME="$TEST_TEMP_DIR/fake_home"
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

@test "is_content_repo_installed detects missing repository" {
    run is_content_repo_installed
    assert_failure
}

@test "is_content_repo_installed detects existing repository" {
    mkdir -p "$HOME/Repos/ooloth/content"
    touch "$HOME/Repos/ooloth/content/README.md"
    
    run is_content_repo_installed
    assert_success
    assert_output --partial "Content repository is already installed"
}

@test "install_content_repo creates repository" {
    # Mock git clone command to succeed
    git() {
        if [[ "$1" == "clone" ]]; then
            mkdir -p "$3"
            touch "$3/README.md"
            return 0
        fi
        return 1
    }
    
    # Mock timeout command
    timeout() {
        shift  # Skip timeout value
        "$@"   # Execute the rest
    }
    
    run install_content_repo
    assert_success
    assert_output --partial "Content repository cloned successfully"
}