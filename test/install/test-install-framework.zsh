#!/usr/bin/env zsh

# Test the basic installation testing framework functionality
# This focuses on core functionality that works reliably

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

# Test installation test environment setup
test_install_environment_setup() {
    test_suite "Installation Test Environment"
    
    test_case "Should create installation test directories"
    
    setup_install_test_environment
    
    # Verify test directories were created
    assert_directory_created "$INSTALL_TEST_HOMEBREW_DIR"
    assert_directory_created "$INSTALL_TEST_SSH_DIR"
    assert_directory_created "$INSTALL_TEST_CONFIG_DIR"
    assert_directory_created "$INSTALL_TEST_HOME"
    assert_directory_created "$INSTALL_TEST_LOCAL"
    
    cleanup_install_test_environment
    
    test_suite_end
}

# Test file and symlink assertions
test_install_file_assertions() {
    test_suite "Installation File Assertions"
    
    setup_install_test_environment
    
    test_case "Should validate file creation"
    
    # Create test files
    local test_file="$INSTALL_TEST_HOME/test.txt"
    echo "test content" > "$test_file"
    
    assert_file_created "$test_file"
    
    test_case "Should validate symlink creation"
    
    # Create test symlink
    local link_path="$INSTALL_TEST_HOME/test_link"
    local target_path="$test_file"
    ln -s "$target_path" "$link_path"
    
    assert_symlink_created "$link_path" "$target_path"
    
    cleanup_install_test_environment
    
    test_suite_end
}

# Test script execution
test_script_execution() {
    test_suite "Installation Script Execution"
    
    setup_install_test_environment
    
    test_case "Should execute simple scripts successfully"
    
    # Create a simple test script
    local test_script="$TEST_TEMP_DIR/simple_test.zsh"
    cat > "$test_script" << 'EOF'
#!/usr/bin/env zsh
echo "Test script starting"
mkdir -p "$HOME/.config/test"
echo "config content" > "$HOME/.config/test/config.txt"
echo "Test script complete"
exit 0
EOF
    chmod +x "$test_script"
    
    # Run the test script
    run_install_script "$test_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_successful "simple_test.zsh" "$exit_code"
    
    # Verify output contains expected messages
    assert_install_output_contains "Test script starting"
    assert_install_output_contains "Test script complete"
    
    # Verify files were created in test environment
    assert_file_created "$INSTALL_TEST_HOME/.config/test/config.txt"
    
    test_case "Should handle script failures appropriately"
    
    # Create a failing test script
    local failing_script="$TEST_TEMP_DIR/failing_test.zsh"
    cat > "$failing_script" << 'EOF'
#!/usr/bin/env zsh
echo "Script starting"
echo "Error: Something went wrong" >&2
exit 1
EOF
    chmod +x "$failing_script"
    
    # Run the failing script
    run_install_script "$failing_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_failed "failing_test.zsh" "$exit_code"
    
    # Verify error output
    assert_install_output_contains "Error: Something went wrong"
    
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_install_environment_setup
    test_install_file_assertions
    test_script_execution
}

# Execute tests
main