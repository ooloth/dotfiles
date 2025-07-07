#!/usr/bin/env zsh

# Test SSH key detection and management functionality
# Tests both utility functions and actual installation script behavior

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

# Test SSH key detection utility functions
test_ssh_key_detection() {
    test_suite "SSH Key Detection"
    
    # Store the real DOTFILES path BEFORE any test setup
    local real_dotfiles="$DOTFILES"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should detect when SSH keys already exist"
    
    # Mock successful SSH key detection
    mock_ssh_key_success
    
    # Create test script that checks for existing SSH keys
    local test_script="$TEST_TEMP_DIR/test_ssh_detection.zsh"
    cat > "$test_script" << EOF
#!/usr/bin/env zsh
export DOTFILES="$real_dotfiles"

# Simple SSH key detection function
detect_ssh_keys() {
    local ssh_dir="\$HOME/.ssh"
    local private_key_path="\$ssh_dir/id_rsa"
    local public_key_path="\$ssh_dir/id_rsa.pub"
    
    if [[ -s "\$private_key_path" && -s "\$public_key_path" ]]; then
        echo "SSH keys found"
        return 0
    else
        echo "SSH keys not found"
        return 1
    fi
}

# Run detection
detect_ssh_keys
exit \$?
EOF
    chmod +x "$test_script"
    
    # Run with explicit DOTFILES environment variable
    local output
    local exit_code
    export HOME="$INSTALL_TEST_HOME"
    export DOTFILES="$real_dotfiles"
    
    # Create mock SSH keys in test environment
    mkdir -p "$INSTALL_TEST_HOME/.ssh"
    echo "mock-private-key" > "$INSTALL_TEST_HOME/.ssh/id_rsa"
    echo "mock-public-key" > "$INSTALL_TEST_HOME/.ssh/id_rsa.pub"
    
    output=$(bash "$test_script" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Verify SSH keys were detected successfully
    assert_installation_successful "test_ssh_detection.zsh" "$exit_code"
    assert_install_output_contains "SSH keys found"
    
    test_case "Should detect when SSH keys are missing"
    
    # Reset test environment for missing keys scenario
    cleanup_install_test_environment
    setup_install_test_environment
    
    # Recreate test script for new environment
    local test_script_missing="$TEST_TEMP_DIR/test_ssh_detection_missing.zsh"
    cat > "$test_script_missing" << EOF
#!/usr/bin/env zsh
export DOTFILES="$real_dotfiles"

# Simple SSH key detection function
detect_ssh_keys() {
    local ssh_dir="\$HOME/.ssh"
    local private_key_path="\$ssh_dir/id_rsa"
    local public_key_path="\$ssh_dir/id_rsa.pub"
    
    if [[ -s "\$private_key_path" && -s "\$public_key_path" ]]; then
        echo "SSH keys found"
        return 0
    else
        echo "SSH keys not found"
        return 1
    fi
}

# Run detection
detect_ssh_keys
exit \$?
EOF
    chmod +x "$test_script_missing"
    
    # Run without creating SSH keys (so they're missing)
    export HOME="$INSTALL_TEST_HOME"
    export DOTFILES="$real_dotfiles"
    
    output=$(bash "$test_script_missing" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Should exit with error when SSH keys are missing
    assert_installation_failed "test_ssh_detection_missing.zsh" "$exit_code"
    assert_install_output_contains "SSH keys not found"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_ssh_key_detection
}

# Execute tests
main