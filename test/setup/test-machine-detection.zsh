#!/usr/bin/env zsh

# Test machine detection functionality
# This is a failing test that will be implemented in PR 2

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Test machine detection functions
test_machine_detection() {
    test_suite "Machine Detection"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should detect Air from hostname"
    # This test will fail until we implement dynamic detection
    # For now, it demonstrates the testing framework
    
    # Mock hostname command
    mock_command "hostname" 0 "Michaels-MacBook-Air.local"
    
    # Test the detection (this function doesn't exist yet)
    if command -v detect_machine_type >/dev/null 2>&1; then
        local machine_type=$(detect_machine_type)
        assert_equals "air" "$machine_type" "Should detect Air from hostname"
    else
        # Expected to fail - function doesn't exist yet
        assert_false "true" "detect_machine_type function not implemented yet (expected failure)"
    fi
    
    test_case "Should detect Mini from hostname"
    # Mock hostname command
    mock_command "hostname" 0 "Michaels-Mac-Mini.local"
    
    if command -v detect_machine_type >/dev/null 2>&1; then
        local machine_type=$(detect_machine_type)
        assert_equals "mini" "$machine_type" "Should detect Mini from hostname"
    else
        # Expected to fail - function doesn't exist yet
        assert_false "true" "detect_machine_type function not implemented yet (expected failure)"
    fi
    
    test_case "Should detect Work from unknown hostname"
    # Mock hostname command
    mock_command "hostname" 0 "work-laptop.company.com"
    
    if command -v detect_machine_type >/dev/null 2>&1; then
        local machine_type=$(detect_machine_type)
        assert_equals "work" "$machine_type" "Should default to work for unknown hostnames"
    else
        # Expected to fail - function doesn't exist yet
        assert_false "true" "detect_machine_type function not implemented yet (expected failure)"
    fi
    
    test_case "Should handle environment variable override"
    # Mock hostname and set environment variable
    mock_command "hostname" 0 "Michaels-MacBook-Air.local"
    export MACHINE="mini"
    
    if command -v detect_machine_type >/dev/null 2>&1; then
        local machine_type=$(detect_machine_type)
        assert_equals "mini" "$machine_type" "Should use environment variable override"
    else
        # Expected to fail - function doesn't exist yet
        assert_false "true" "detect_machine_type function not implemented yet (expected failure)"
    fi
    
    # Clean up
    unset MACHINE
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test current hardcoded behavior
test_current_hardcoded_behavior() {
    test_suite "Current Hardcoded Behavior"
    
    test_case "Should have hardcoded machine variables in setup.zsh"
    # Test that the current setup.zsh has hardcoded variables
    local setup_file="$ORIGINAL_DOTFILES/setup.zsh"
    
    assert_file_exists "$setup_file" "setup.zsh should exist"
    
    # Check for hardcoded variables
    if grep -q "export IS_AIR=" "$setup_file"; then
        assert_true "true" "setup.zsh contains hardcoded IS_AIR variable"
    else
        assert_false "true" "setup.zsh should contain hardcoded IS_AIR variable"
    fi
    
    if grep -q "export IS_MINI=" "$setup_file"; then
        assert_true "true" "setup.zsh contains hardcoded IS_MINI variable"
    else
        assert_false "true" "setup.zsh should contain hardcoded IS_MINI variable"
    fi
    
    if grep -q "export IS_WORK=" "$setup_file"; then
        assert_true "true" "setup.zsh contains hardcoded IS_WORK variable"
    else
        assert_false "true" "setup.zsh should contain hardcoded IS_WORK variable"
    fi
    
    test_suite_end
}

# Test framework validation
test_framework_validation() {
    test_suite "Test Framework Validation"
    
    setup_test_environment
    init_mocking
    
    test_case "Should create test environment"
    assert_directory_exists "$TEST_TEMP_DIR" "Test temp directory should exist"
    assert_directory_exists "$TEST_HOME" "Test home directory should exist"
    assert_directory_exists "$TEST_DOTFILES" "Test dotfiles directory should exist"
    
    test_case "Should support command mocking"
    mock_command "test_command" 42 "test output"
    
    # Test that the mock works
    local output=$(test_command 2>&1)
    local exit_code=$?
    
    assert_equals "42" "$exit_code" "Mock should return correct exit code"
    assert_equals "test output" "$output" "Mock should return correct output"
    
    test_case "Should track command calls"
    mock_command "tracked_command" 0 "tracked output"
    
    # Call the command multiple times
    tracked_command arg1 arg2
    tracked_command arg3 arg4
    
    assert_command_called "tracked_command" 2 "Should track command calls"
    assert_command_called_with "tracked_command" "arg1 arg2" "Should track command arguments"
    assert_command_called_with "tracked_command" "arg3 arg4" "Should track second call arguments"
    
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_framework_validation
    test_current_hardcoded_behavior
    test_machine_detection
}

# Execute tests
main