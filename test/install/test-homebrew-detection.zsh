#!/usr/bin/env zsh

# Test Homebrew binary detection functionality
# This focuses on testing the ability to detect if Homebrew is installed

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

# Test Homebrew binary detection
test_homebrew_binary_detection() {
    test_suite "Homebrew Binary Detection"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should detect when Homebrew is already installed"
    
    # Mock successful Homebrew installation
    mock_homebrew_success
    
    # Create test script that checks for Homebrew using inline function for now
    local test_script="$TEST_TEMP_DIR/homebrew_check.zsh"
    cat > "$test_script" << 'EOF'
#!/usr/bin/env zsh

# Simple Homebrew detection function for testing
detect_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is installed"
        return 0
    else
        echo "Homebrew is not installed"
        return 1
    fi
}

# Run detection
detect_homebrew
exit $?
EOF
    chmod +x "$test_script"
    
    # Run the detection script
    run_install_script "$test_script"
    local exit_code
    exit_code=$(get_install_exit_code)
    
    # Verify Homebrew was detected successfully
    assert_installation_successful "homebrew_check.zsh" "$exit_code"
    assert_install_output_contains "Homebrew is installed"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run the test
main() {
    test_homebrew_binary_detection
}

# Execute test
main