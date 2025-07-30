#!/usr/bin/env bats

# Integration tests for content installation

# Load test helpers and utils
load "../../../core/testing/bats-helper.bash"
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    mkdir -p "$HOME"
    mkdir -p "$DOTFILES/features/content"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "is_content_repo_installed returns false when repo doesn't exist" {
    run is_content_repo_installed
    assert_failure
}

@test "is_content_repo_installed returns true when repo exists" {
    # Create fake content repository
    mkdir -p "$HOME/Repos/content"
    touch "$HOME/Repos/content/README.md"
    
    run is_content_repo_installed
    assert_success
}

@test "install_content_repo creates repository directory" {
    # Mock git clone command
    git() {
        if [[ "$1" == "clone" ]]; then
            mkdir -p "$3"
            touch "$3/README.md"
            return 0
        fi
        return 1
    }
    
    run install_content_repo
    assert_success
    assert [ -d "$HOME/Repos/content" ]
}

@test "install_content_repo skips when repo already exists" {
    # Create existing repository
    mkdir -p "$HOME/Repos/content"
    touch "$HOME/Repos/content/README.md"
    
    run install_content_repo
    assert_success
    assert_output --partial "already installed"
}