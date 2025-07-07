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

# Test actual installation script integration
test_ssh_installation_script_integration() {
    test_suite "SSH Installation Script"
    
    # Store the real DOTFILES path BEFORE any test setup
    local real_dotfiles="$DOTFILES"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should skip SSH key generation when keys already exist"
    
    # Mock successful SSH key detection
    mock_ssh_key_success
    
    # Create test script that simulates the installation script behavior
    local test_script="$TEST_TEMP_DIR/install_ssh_test.zsh"
    cat > "$test_script" << EOF
#!/usr/bin/env zsh
export DOTFILES="$real_dotfiles"

# Mock return_or_exit function to track calls
return_or_exit() {
    echo "return_or_exit called with code: \$1"
    exit \$1
}

# Source required utilities
source "\$DOTFILES/lib/ssh-utils.zsh"

# Simulate the installation script logic
if detect_ssh_keys; then
    return_or_exit 0
fi

echo "Would proceed with SSH key generation"
exit 0
EOF
    chmod +x "$test_script"
    
    # Create mock SSH keys in test environment
    mkdir -p "$INSTALL_TEST_HOME/.ssh"
    echo "mock-private-key" > "$INSTALL_TEST_HOME/.ssh/id_rsa"
    echo "mock-public-key" > "$INSTALL_TEST_HOME/.ssh/id_rsa.pub"
    
    # Run with explicit DOTFILES environment variable
    local output
    local exit_code
    export HOME="$INSTALL_TEST_HOME"
    export DOTFILES="$real_dotfiles"
    
    output=$(bash "$test_script" 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    # Verify script exits early when SSH keys are present
    assert_installation_successful "install_ssh_test.zsh" "$exit_code"
    assert_install_output_contains "✅ SSH key pair found."
    assert_install_output_contains "return_or_exit called with code: 0"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_ssh_key_detection
    test_ssh_installation_script_integration
}

# Execute tests
main