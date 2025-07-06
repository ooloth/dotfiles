#!/usr/bin/env zsh

# Test prerequisite validation functionality
# This implements TDD for comprehensive system checks before installation

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Source the prerequisite validation module we're testing
source "$ORIGINAL_DOTFILES/bin/lib/prerequisite-validation.zsh"

# Test Command Line Tools validation
test_command_line_tools_validation() {
    test_suite "Command Line Tools Validation"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should detect when Command Line Tools are installed"
    # Create a mock CommandLineTools directory structure in test environment
    local mock_path="$TEST_TEMP_DIR/CommandLineTools"
    mkdir -p "$mock_path/usr/bin"
    touch "$mock_path/usr/bin/git"
    
    # Mock xcode-select command to return our test path
    mock_command "xcode-select" 0 "$mock_path"
    
    # Test the validation
    validate_command_line_tools
    assert_equals "0" "$?" "Should return success when tools are installed"
    
    test_case "Should detect when Command Line Tools are missing"
    # Mock xcode-select command to return failure
    mock_command "xcode-select" 2 "xcode-select: error: unable to get active developer directory"
    
    # Test the validation
    validate_command_line_tools
    assert_not_equals "0" "$?" "Should return failure when tools are missing"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test network connectivity validation
test_network_connectivity_validation() {
    test_suite "Network Connectivity Validation"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should validate GitHub connectivity"
    # Mock ping command to return success for all hosts
    mock_command "ping" 0 "PING github.com: 56 data bytes"
    
    # Test the validation
    validate_network_connectivity
    assert_equals "0" "$?" "Should return success when GitHub is reachable"
    
    test_case "Should detect network connectivity issues"
    # Mock ping command to return failure
    mock_command "ping" 1 "ping: cannot resolve github.com: Unknown host"
    
    # Test the validation
    validate_network_connectivity
    assert_not_equals "0" "$?" "Should return failure when network is unreachable"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test directory and permissions validation
test_directory_permissions_validation() {
    test_suite "Directory and Permissions Validation"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should validate required directories exist"
    # Create test directories
    mkdir -p "$TEST_HOME/test-dir"
    
    # Test the validation
    validate_directory_permissions "$TEST_HOME/test-dir"
    assert_equals "0" "$?" "Should return success when directory exists"
    
    test_case "Should detect missing directories"
    # Test with non-existent directory
    validate_directory_permissions "$TEST_HOME/non-existent"
    assert_not_equals "0" "$?" "Should return failure when directory doesn't exist"
    
    test_case "Should validate write permissions"
    # Create a directory with write permissions
    mkdir -p "$TEST_HOME/writable-dir"
    chmod 755 "$TEST_HOME/writable-dir"
    
    # Test the validation
    validate_write_permissions "$TEST_HOME/writable-dir"
    assert_equals "0" "$?" "Should return success when directory is writable"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test macOS version compatibility
test_macos_version_validation() {
    test_suite "macOS Version Validation"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should validate supported macOS version"
    # Mock sw_vers command to return supported version
    mock_command "sw_vers" 0 "14.0"
    
    # Test the validation
    validate_macos_version
    assert_equals "0" "$?" "Should return success for supported macOS version"
    
    test_case "Should detect unsupported macOS version"
    # Mock sw_vers command to return old version
    mock_command "sw_vers" 0 "10.15"
    
    # Test the validation
    validate_macos_version
    assert_not_equals "0" "$?" "Should return failure for unsupported macOS version"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test comprehensive prerequisite validation
test_comprehensive_validation() {
    test_suite "Comprehensive Prerequisite Validation"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should run all prerequisite checks"
    # Create mock CommandLineTools directory
    local mock_path="$TEST_TEMP_DIR/CommandLineTools"
    mkdir -p "$mock_path/usr/bin"
    touch "$mock_path/usr/bin/git"
    
    # Mock all commands to return success
    mock_command "xcode-select" 0 "$mock_path"
    mock_command "ping" 0 "PING github.com: 56 data bytes"
    mock_command "sw_vers" 0 "14.0"
    
    # Test the validation
    run_prerequisite_validation
    assert_equals "0" "$?" "Should return success when all checks pass"
    
    test_case "Should fail when any prerequisite check fails"
    # Mock one command to fail
    mock_command "xcode-select" 2 "xcode-select: error: unable to get active developer directory"
    mock_command "ping" 0 "PING github.com: 56 data bytes"
    mock_command "sw_vers" 0 "14.0"
    
    # Test the validation
    run_prerequisite_validation
    assert_not_equals "0" "$?" "Should return failure when any check fails"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_command_line_tools_validation
    test_network_connectivity_validation
    test_directory_permissions_validation
    test_macos_version_validation
    test_comprehensive_validation
}

# Execute tests
main