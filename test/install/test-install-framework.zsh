#!/usr/bin/env zsh

# Test the installation testing framework itself
# This ensures our testing utilities and mocks work correctly

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
    assert_directory_created "$INSTALL_TEST_HOMEBREW_DIR" "Homebrew test directory should be created"
    assert_directory_created "$INSTALL_TEST_SSH_DIR" "SSH test directory should be created"
    assert_directory_created "$INSTALL_TEST_CONFIG_DIR" "Config test directory should be created"
    assert_directory_created "$INSTALL_TEST_HOME" "Mock home directory should be created"
    assert_directory_created "$INSTALL_TEST_LOCAL" "Mock local directory should be created"
    
    cleanup_install_test_environment
    
    test_suite_end
}

# Test installation mocking capabilities
test_install_mocking() {
    test_suite "Installation Mocking Framework"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should mock Homebrew commands successfully"
    
    # Test that brew commands are mocked
    local brew_output
    brew_output=$(brew --version 2>&1)
    local brew_exit_code=$?
    
    assert_equals "0" "$brew_exit_code" "Mocked brew command should succeed"
    if echo "$brew_output" | grep -q "Homebrew"; then
        assert_true "true" "Mocked brew should return version info"
    else
        assert_false "true" "Mocked brew should return version info"
    fi
    
    test_case "Should mock SSH commands successfully"
    
    # Test that ssh-keygen commands are mocked
    local ssh_output
    ssh_output=$(ssh-keygen -t ed25519 2>&1)
    local ssh_exit_code=$?
    
    assert_equals "0" "$ssh_exit_code" "Mocked ssh-keygen command should succeed"
    if echo "$ssh_output" | grep -q "Generating"; then
        assert_true "true" "Mocked ssh-keygen should return generation message"
    else
        assert_false "true" "Mocked ssh-keygen should return generation message"
    fi
    
    test_case "Should track command execution for verification"
    
    # Execute some commands
    brew install git
    ssh-keygen -t rsa
    
    # Verify command tracking works
    verify_homebrew_called
    verify_ssh_keygen_called
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Test installation assertion utilities
test_install_assertions() {
    test_suite "Installation Assertion Utilities"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should validate file creation assertions"
    
    # Create test files
    local test_file="$INSTALL_TEST_HOME/test.txt"
    echo "test content" > "$test_file"
    
    assert_file_created "$test_file" "Test file should be detected as created"
    
    test_case "Should validate symlink creation assertions"
    
    # Create test symlink
    local link_path="$INSTALL_TEST_HOME/test_link"
    local target_path="$test_file"
    ln -s "$target_path" "$link_path"
    
    assert_symlink_created "$link_path" "$target_path" "Test symlink should be detected correctly"
    
    test_case "Should validate command execution assertions"
    
    # Execute commands and verify tracking
    git --version
    brew doctor
    
    assert_command_executed "git --version" "Git version command should be tracked"
    assert_command_executed "brew doctor" "Brew doctor command should be tracked"
    assert_command_not_executed "npm install" "Npm install should not be tracked"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Test installation script execution utilities
test_install_script_execution() {
    test_suite "Installation Script Execution"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should execute scripts in test environment"
    
    # Create a test installation script
    local test_script="$TEST_TEMP_DIR/test_install.zsh"
    cat > "$test_script" << 'EOF'
#!/usr/bin/env zsh
echo "Test installation starting"
mkdir -p "$HOME/.config/test"
echo "config content" > "$HOME/.config/test/config.txt"
brew install test-package
echo "Test installation complete"
exit 0
EOF
    chmod +x "$test_script"
    
    # Run the test script
    run_install_script "$test_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_successful "test_install.zsh" "$exit_code"
    
    # Verify output contains expected messages
    assert_install_output_contains "Test installation starting"
    assert_install_output_contains "Test installation complete"
    
    # Verify files were created in test environment
    assert_file_created "$INSTALL_TEST_HOME/.config/test/config.txt"
    
    # Verify commands were executed
    verify_homebrew_called
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Test failure scenarios
test_install_failure_scenarios() {
    test_suite "Installation Failure Scenarios"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should handle script failures appropriately"
    
    # Create a failing test script
    local failing_script="$TEST_TEMP_DIR/failing_install.zsh"
    cat > "$failing_script" << 'EOF'
#!/usr/bin/env zsh
echo "Installation starting"
echo "Error: Something went wrong" >&2
exit 1
EOF
    chmod +x "$failing_script"
    
    # Run the failing script
    run_install_script "$failing_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_failed "failing_install.zsh" "$exit_code"
    
    # Verify error output
    assert_install_output_contains "Error: Something went wrong"
    
    test_case "Should handle network failure scenarios"
    
    # Mock network failures
    mock_network_failure
    
    # Create script that depends on network
    local network_script="$TEST_TEMP_DIR/network_install.zsh"
    cat > "$network_script" << 'EOF'
#!/usr/bin/env zsh
# This script should fail when network commands fail
curl -fsSL https://example.com/install.sh
if [[ $? -ne 0 ]]; then
    echo "Network download failed"
    exit 1
fi
git clone https://github.com/example/repo.git
if [[ $? -ne 0 ]]; then
    echo "Git clone failed"
    exit 1
fi
echo "Installation completed"
EOF
    chmod +x "$network_script"
    
    # Run script with network failures
    run_install_script "$network_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_failed "network_install.zsh" "$exit_code"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Test integration with existing utilities
test_framework_integration() {
    test_suite "Framework Integration"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should integrate with dry-run utilities"
    
    # Source dry-run utilities
    source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
    
    # Test dry-run mode
    export DRY_RUN_MODE="true"
    
    # Create script that uses dry-run utilities
    local dry_run_script="$TEST_TEMP_DIR/dry_run_install.zsh"
    cat > "$dry_run_script" << EOF
#!/usr/bin/env zsh
# Set DOTFILES if not already set
export DOTFILES="\${DOTFILES:-$ORIGINAL_DOTFILES}"
source "\$DOTFILES/bin/lib/dry-run-utils.zsh"
parse_dry_run_flags "\$@"

dry_run_execute "brew install git"
dry_run_execute "mkdir -p ~/.config"
dry_run_log "Installation would complete successfully"
EOF
    chmod +x "$dry_run_script"
    
    # Run in dry-run mode
    run_install_script "$dry_run_script" "--dry-run"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    assert_installation_successful "dry_run_install.zsh" "$exit_code"
    
    # Verify dry-run output
    assert_install_output_contains "[DRY RUN]"
    assert_install_output_contains "brew install git"
    
    # Verify commands were NOT actually executed
    verify_homebrew_not_called
    
    unset DRY_RUN_MODE
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_install_environment_setup
    test_install_mocking
    test_install_assertions
    test_install_script_execution
    test_install_failure_scenarios
    test_framework_integration
}

# Execute tests
main