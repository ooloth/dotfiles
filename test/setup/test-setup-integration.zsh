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
    
    test_case "Should continue when prerequisites pass"
    # Test the prerequisite validation function directly instead of full setup.zsh
    # This avoids the complexity of mocking interactive elements like vared
    
    # Mock all prerequisite validation commands to succeed
    local mock_tools_path="$TEST_TEMP_DIR/CommandLineTools"
    mkdir -p "$mock_tools_path/usr/bin"
    touch "$mock_tools_path/usr/bin/git"
    mock_command "xcode-select" 0 "$mock_tools_path"
    mock_command "ping" 0 "PING github.com: 56 data bytes"
    mock_command "sw_vers" 0 "14.0"
    
    # Source the prerequisite validation module
    source "$ORIGINAL_DOTFILES/bin/lib/prerequisite-validation.zsh"
    
    # Test that the validation function passes when all prerequisites are met
    local validation_output
    validation_output=$(run_prerequisite_validation 2>&1)
    local validation_exit_code=$?
    
    # Check that validation passed
    assert_equals "0" "$validation_exit_code" "Prerequisite validation should pass when all requirements are met"
    
    # Check that success message is present
    if echo "$validation_output" | grep -q "All prerequisite validation checks passed"; then
        assert_true "true" "Should show success message when prerequisites pass"
    else
        assert_false "true" "Should show success message when prerequisites pass"
    fi
    
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