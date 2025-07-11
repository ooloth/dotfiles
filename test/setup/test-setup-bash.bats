#!/usr/bin/env bats

# Test setup.bash main entry point

setup() {
    # Save original environment
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    export ORIGINAL_HOME="${HOME:-}"
    
    # Create temporary directory for testing
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTFILES="$TEST_TEMP_DIR/home/Repos/ooloth/dotfiles"
    mkdir -p "$HOME"
    mkdir -p "$DOTFILES"
}

teardown() {
    # Restore original environment
    if [[ -n "$ORIGINAL_DOTFILES" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    if [[ -n "$ORIGINAL_HOME" ]]; then
        export HOME="$ORIGINAL_HOME"
    else
        unset HOME
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "setup.bash exists and is executable" {
    # Check if setup.bash exists in the real dotfiles location
    [ -f "$(pwd)/setup.bash" ]
    [ -x "$(pwd)/setup.bash" ]
}