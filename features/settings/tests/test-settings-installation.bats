#!/usr/bin/env bats

# Integration tests for settings installation

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
    export HOME="$TEST_TEMP_DIR"
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
    
    mkdir -p "$DOTFILES/features/settings"
    
    # Mock macOS detection
    export OSTYPE="darwin21"
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

@test "settings installation runs on macOS with required commands" {
    # Mock required commands
    defaults() { return 0; }
    chflags() { return 0; }
    export -f defaults chflags
    
    # Source the installation script
    source "$DOTFILES/../../../features/settings/install.bash"
    
    run main
    assert_success
}

@test "settings installation skips on non-macOS systems" {
    export OSTYPE="linux-gnu"
    
    # Source the installation script
    source "$DOTFILES/../../../features/settings/install.bash"
    
    run main
    assert_success
    assert_output --partial "Skipping settings configuration"
}

@test "settings installation fails when defaults command unavailable" {
    # Remove defaults from PATH
    export PATH="/usr/bin:/bin"
    
    # Source the installation script
    source "$DOTFILES/../../../features/settings/install.bash"
    
    run configure_general_settings
    assert_failure
}

@test "settings installation fails when chflags command unavailable" {
    defaults() { return 0; }
    export -f defaults
    
    # Remove chflags from PATH
    export PATH="/usr/bin:/bin"
    
    # Source the installation script
    source "$DOTFILES/../../../features/settings/install.bash"
    
    run configure_finder_settings
    assert_failure
}