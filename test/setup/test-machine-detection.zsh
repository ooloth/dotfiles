#!/usr/bin/env zsh

# Test machine detection functionality
# This is a failing test that will be implemented in PR 2

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Source the machine detection module we're testing
source "$ORIGINAL_DOTFILES/bin/lib/machine-detection.zsh"

# Test machine detection functions
test_machine_detection() {
    test_suite "Machine Detection"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should detect Air from hostname"
    # Mock hostname command
    mock_command "hostname" 0 "Michaels-MacBook-Air.local"
    
    # Clear any existing MACHINE environment variable
    unset MACHINE
    
    # Test the detection
    local machine_type=$(detect_machine_type)
    assert_equals "air" "$machine_type" "Should detect Air from hostname"
    
    test_case "Should detect Mini from hostname"
    # Mock hostname command
    mock_command "hostname" 0 "Michaels-Mac-Mini.local"
    
    # Clear any existing MACHINE environment variable
    unset MACHINE
    
    # Test the detection
    local machine_type=$(detect_machine_type)
    assert_equals "mini" "$machine_type" "Should detect Mini from hostname"
    
    test_case "Should detect Work from unknown hostname"
    # Mock hostname command
    mock_command "hostname" 0 "work-laptop.company.com"
    
    # Clear any existing MACHINE environment variable
    unset MACHINE
    
    # Test the detection
    local machine_type=$(detect_machine_type)
    assert_equals "work" "$machine_type" "Should default to work for unknown hostnames"
    
    test_case "Should handle environment variable override"
    # Mock hostname and set environment variable
    mock_command "hostname" 0 "Michaels-MacBook-Air.local"
    export MACHINE="mini"
    
    # Test the detection with override
    local machine_type=$(detect_machine_type)
    assert_equals "mini" "$machine_type" "Should use environment variable override"
    
    # Clean up
    unset MACHINE
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test dynamic behavior replaces hardcoded behavior
test_dynamic_behavior() {
    test_suite "Dynamic Machine Detection Integration"
    
    test_case "Should have removed hardcoded machine variables from setup.zsh"
    # Test that setup.zsh no longer has hardcoded variables
    local setup_file="$ORIGINAL_DOTFILES/setup.zsh"
    
    assert_file_exists "$setup_file" "setup.zsh should exist"
    
    # Check that hardcoded variables are removed
    if grep -q "export IS_AIR=" "$setup_file"; then
        assert_false "true" "setup.zsh should not contain hardcoded IS_AIR variable"
    else
        assert_true "true" "setup.zsh correctly removed hardcoded IS_AIR variable"
    fi
    
    if grep -q "export IS_MINI=" "$setup_file"; then
        assert_false "true" "setup.zsh should not contain hardcoded IS_MINI variable"
    else
        assert_true "true" "setup.zsh correctly removed hardcoded IS_MINI variable"
    fi
    
    if grep -q "export IS_WORK=" "$setup_file"; then
        assert_false "true" "setup.zsh should not contain hardcoded IS_WORK variable"
    else
        assert_true "true" "setup.zsh correctly removed hardcoded IS_WORK variable"
    fi
    
    test_case "Should use dynamic machine detection"
    # Check that setup.zsh sources the machine detection module
    if grep -q "machine-detection.zsh" "$setup_file"; then
        assert_true "true" "setup.zsh sources machine detection module"
    else
        assert_false "true" "setup.zsh should source machine detection module"
    fi
    
    if grep -q "init_machine_detection" "$setup_file"; then
        assert_true "true" "setup.zsh calls init_machine_detection"
    else
        assert_false "true" "setup.zsh should call init_machine_detection"
    fi
    
    test_suite_end
}

# Test machine variable setting functionality
test_machine_variables() {
    test_suite "Machine Variable Setting"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should set IS_AIR=true for air machine type"
    set_machine_variables "air"
    assert_equals "true" "$IS_AIR" "IS_AIR should be true for air type"
    assert_equals "false" "$IS_MINI" "IS_MINI should be false for air type"
    assert_equals "false" "$IS_WORK" "IS_WORK should be false for air type"
    assert_equals "air" "$MACHINE" "MACHINE should be set to air"
    
    test_case "Should set IS_MINI=true for mini machine type"
    set_machine_variables "mini"
    assert_equals "false" "$IS_AIR" "IS_AIR should be false for mini type"
    assert_equals "true" "$IS_MINI" "IS_MINI should be true for mini type"
    assert_equals "false" "$IS_WORK" "IS_WORK should be false for mini type"
    assert_equals "mini" "$MACHINE" "MACHINE should be set to mini"
    
    test_case "Should set IS_WORK=true for work machine type"
    set_machine_variables "work"
    assert_equals "false" "$IS_AIR" "IS_AIR should be false for work type"
    assert_equals "false" "$IS_MINI" "IS_MINI should be false for work type"
    assert_equals "true" "$IS_WORK" "IS_WORK should be true for work type"
    assert_equals "work" "$MACHINE" "MACHINE should be set to work"
    
    test_case "Should default to work for unknown machine type"
    set_machine_variables "unknown"
    assert_equals "false" "$IS_AIR" "IS_AIR should be false for unknown type"
    assert_equals "false" "$IS_MINI" "IS_MINI should be false for unknown type"
    assert_equals "true" "$IS_WORK" "IS_WORK should be true for unknown type"
    assert_equals "work" "$MACHINE" "MACHINE should default to work"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test init_machine_detection integration function
test_init_machine_detection() {
    test_suite "Machine Detection Initialization"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should initialize machine detection and set variables"
    # Mock hostname command
    mock_command "hostname" 0 "Michaels-MacBook-Air.local"
    
    # Clear any existing variables
    unset MACHINE IS_AIR IS_MINI IS_WORK
    
    # Call the initialization function
    init_machine_detection
    
    # Verify variables are set correctly
    assert_equals "air" "$MACHINE" "MACHINE should be detected and set"
    assert_equals "true" "$IS_AIR" "IS_AIR should be set to true"
    assert_equals "false" "$IS_MINI" "IS_MINI should be set to false"
    assert_equals "false" "$IS_WORK" "IS_WORK should be set to false"
    
    test_case "Should handle missing hostname command gracefully"
    # Mock hostname command to fail
    mock_command "hostname" 1 ""
    
    # Clear variables
    unset MACHINE IS_AIR IS_MINI IS_WORK
    
    # Should still work using fallback
    init_machine_detection
    
    # Should default to work when hostname fails
    assert_equals "work" "$MACHINE" "Should default to work when hostname fails"
    assert_equals "true" "$IS_WORK" "IS_WORK should be true when hostname fails"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
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
    
    # Test that the mock works - capture exit code properly
    local output_file="$TEST_TEMP_DIR/test_output"
    test_command > "$output_file" 2>&1
    local exit_code=$?
    local output=$(cat "$output_file")
    
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
    test_dynamic_behavior
    test_machine_detection
    test_machine_variables
    test_init_machine_detection
}

# Execute tests
main