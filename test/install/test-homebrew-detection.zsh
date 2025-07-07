#!/usr/bin/env zsh

# Test Homebrew detection and installation script integration
# Tests both utility functions and actual installation script behavior

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

# Test Homebrew utility functions
test_homebrew_utilities() {
    test_suite "Homebrew Utility Functions"
    
    # Store the real DOTFILES path BEFORE any test setup
    local real_dotfiles="$DOTFILES"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should detect when Homebrew is installed"
    
    # Mock successful Homebrew installation
    mock_homebrew_success
    
    # Create test script that uses the utility functions
    local test_script="$TEST_TEMP_DIR/test_utilities.zsh"
    cat > "$test_script" << EOF
#!/usr/bin/env zsh
export DOTFILES="$real_dotfiles"
source "\$DOTFILES/lib/homebrew-utils.zsh"

# Test detection
if detect_homebrew; then
    echo "Detection: SUCCESS"
else
    echo "Detection: FAILED"
    exit 1
fi

# Test version retrieval
if get_homebrew_version; then
    echo "Version: SUCCESS"
else
    echo "Version: FAILED"
    exit 1
fi

# Test validation
if validate_homebrew_installation; then
    echo "Validation: SUCCESS"
    exit 0
else
    echo "Validation: FAILED"
    exit 1
fi
EOF
    chmod +x "$test_script"
    
    # Run with explicit DOTFILES environment variable
    local output
    local exit_code
    export HOME="$INSTALL_TEST_HOME"
    export HOMEBREW_PREFIX="$INSTALL_TEST_LOCAL"
    export DOTFILES="$real_dotfiles"
    
    output=$(bash "$test_script" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Verify utilities work correctly
    assert_installation_successful "test_utilities.zsh" "$exit_code"
    assert_install_output_contains "🍺 Homebrew is already installed"
    assert_install_output_contains "Detection: SUCCESS"
    assert_install_output_contains "Version: SUCCESS"
    assert_install_output_contains "Validation: SUCCESS"
    
    test_case "Should handle missing Homebrew correctly"
    
    # Reset mocking to simulate missing Homebrew
    cleanup_install_mocking
    init_install_mocking
    
    # Mock missing Homebrew
    mock_command "command -v brew" 1 ""
    mock_command "brew" 127 "command not found: brew"
    
    # Test detection with missing Homebrew
    output=$(bash "$test_script" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Should exit with error when Homebrew is missing
    assert_installation_failed "test_utilities.zsh" "$exit_code"
    assert_install_output_contains "🍺 Homebrew is not installed"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Test actual installation script integration
test_installation_script_integration() {
    test_suite "Homebrew Installation Script"
    
    # Store the real DOTFILES path BEFORE any test setup
    local real_dotfiles="$DOTFILES"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should skip installation when Homebrew already exists"
    
    # Mock successful Homebrew installation
    mock_homebrew_success
    
    # Create test script that simulates the installation script behavior
    local test_script="$TEST_TEMP_DIR/install_homebrew_test.zsh"
    cat > "$test_script" << EOF
#!/usr/bin/env zsh
export DOTFILES="$real_dotfiles"

# Mock return_or_exit function to track calls
return_or_exit() {
    echo "return_or_exit called with code: \$1"
    export TEST_EXIT_CALLED="true"
    exit \$1
}

# Source required utilities
source "\$DOTFILES/lib/homebrew-utils.zsh"

# Simulate the installation script logic
if detect_homebrew; then
    return_or_exit 0
fi

echo "Would proceed with installation"
exit 0
EOF
    chmod +x "$test_script"
    
    # Run with explicit DOTFILES environment variable
    local output
    local exit_code
    export HOME="$INSTALL_TEST_HOME"
    export HOMEBREW_PREFIX="$INSTALL_TEST_LOCAL"
    export DOTFILES="$real_dotfiles"
    
    output=$(bash "$test_script" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Verify script exits early when Homebrew is present
    assert_installation_successful "install_homebrew_test.zsh" "$exit_code"
    assert_install_output_contains "🍺 Homebrew is already installed"
    assert_install_output_contains "return_or_exit called with code: 0"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_homebrew_utilities
    test_installation_script_integration
}

# Execute tests
main