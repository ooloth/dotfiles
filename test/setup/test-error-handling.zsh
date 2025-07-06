#!/usr/bin/env zsh

# Test error handling functionality
# This tests improved error handling and recovery mechanisms

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Test error detection and recovery
test_error_detection() {
    test_suite "Error Detection and Recovery"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should detect command failures and provide context"
    
    # Source the error handling utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/error-handling.zsh"
    
    # Test detecting a failed command
    local output
    output=$(capture_error "false" "Installing test package" 2>&1)
    local exit_code=$?
    
    # Should return non-zero exit code
    assert_not_equals "0" "$exit_code" "Should detect command failure"
    
    # Should provide context in error message
    if echo "$output" | grep -q "Installing test package"; then
        assert_true "true" "Should include context in error message"
    else
        assert_false "true" "Should include context in error message"
    fi
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test retry mechanism for transient failures
test_retry_mechanism() {
    test_suite "Retry Mechanism"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should retry failed commands with backoff"
    
    # Source the error handling utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/error-handling.zsh"
    
    # Create a command that fails twice then succeeds using a file counter
    local counter_file="$TEST_TEMP_DIR/retry_counter"
    echo "0" > "$counter_file"
    
    # Create a test script that uses the counter
    cat > "$TEST_TEMP_DIR/test_command.sh" << 'EOF'
#!/usr/bin/env zsh
counter_file="$1"
attempt=$(cat "$counter_file")
((attempt++))
echo "$attempt" > "$counter_file"
if [[ $attempt -lt 3 ]]; then
    exit 1
fi
echo "Success on attempt $attempt"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/test_command.sh"
    
    # Test retry mechanism
    local output
    output=$(retry_with_backoff "$TEST_TEMP_DIR/test_command.sh $counter_file" 3 1 2>&1)
    local exit_code=$?
    
    # Should eventually succeed
    assert_equals "0" "$exit_code" "Should succeed after retries"
    
    # Should show success message
    if echo "$output" | grep -q "Success on attempt 3"; then
        assert_true "true" "Should execute until success"
    else
        assert_false "true" "Should execute until success"
    fi
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test user-friendly error messages
test_user_friendly_errors() {
    test_suite "User-Friendly Error Messages"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should provide helpful error messages with suggestions"
    
    # Source the error handling utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/error-handling.zsh"
    
    # Test user-friendly error message
    local output
    output=$(handle_error "brew install" "EACCES" "Permission denied" 2>&1)
    local exit_code=$?
    
    # Should return error exit code
    assert_not_equals "0" "$exit_code" "Should return error exit code"
    
    # Should include helpful suggestion
    if echo "$output" | grep -q "Try running with sudo"; then
        assert_true "true" "Should suggest using sudo for permission errors"
    else
        assert_false "true" "Should suggest using sudo for permission errors"
    fi
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_error_detection
    test_retry_mechanism
    test_user_friendly_errors
}

# Execute tests
main