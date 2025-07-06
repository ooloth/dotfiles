#!/usr/bin/env zsh

# Test setup.zsh integration with prerequisite validation
# This tests that setup.zsh properly handles prerequisite validation behavior

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Test setup.zsh prerequisite integration
test_setup_prerequisite_integration() {
    test_suite "Setup.zsh Prerequisite Integration"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should exit with error when prerequisites fail"
    local setup_file="$ORIGINAL_DOTFILES/setup.zsh"
    
    assert_file_exists "$setup_file" "setup.zsh should exist"
    
    # Mock all prerequisite validation commands to fail
    mock_command "uname" 0 "Darwin"  # Pass the Mac check
    mock_command "xcode-select" 2 "xcode-select: error: unable to get active developer directory"
    mock_command "ping" 1 "ping: cannot resolve github.com: Unknown host"
    mock_command "sw_vers" 0 "10.15"  # Old version
    
    # Mock vared to automatically answer 'y' to confirmation
    mock_command "vared" 0 ""
    export key="y"
    
    # Run setup.zsh in a subshell and capture exit code
    local exit_code
    (
        cd "$ORIGINAL_DOTFILES"
        timeout 30 zsh setup.zsh 2>/dev/null
    ) 2>/dev/null
    exit_code=$?
    
    assert_not_equals "0" "$exit_code" "setup.zsh should exit with error when prerequisites fail"
    
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_setup_prerequisite_integration
}

# Execute tests
main