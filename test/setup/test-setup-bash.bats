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

@test "setup.bash sets DOTFILES environment variable" {
    # Clear DOTFILES to test that setup.bash sets it
    unset DOTFILES
    
    # Run setup.bash in a way that exports variables
    source "$(pwd)/setup.bash"
    
    # Check that DOTFILES is set correctly
    [ -n "$DOTFILES" ]
    [[ "$DOTFILES" == "$HOME/Repos/ooloth/dotfiles" ]]
}

@test "setup.bash enables strict error handling" {
    # Create a test script that sources setup.bash and checks error handling
    local test_script="$TEST_TEMP_DIR/test_error.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
source "$(pwd)/setup.bash"

# Test that undefined variable causes error
echo "$UNDEFINED_VARIABLE"
EOF
    
    chmod +x "$test_script"
    
    # Run the test script - should fail due to undefined variable
    run "$test_script"
    [ "$status" -ne 0 ]
}

@test "setup.bash shows welcome message when run directly" {
    # Run setup.bash with 'n' response to avoid full installation
    run bash -c "echo 'n' | $(pwd)/setup.bash"
    
    # Check that welcome message is shown
    [[ "$output" =~ "Welcome to your new Mac!" ]]
    [[ "$output" =~ "Sound good?" ]]
    [[ "$output" =~ "No worries! Maybe next time." ]]
    [ "$status" -eq 1 ]
}