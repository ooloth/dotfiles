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

# Run all tests
main() {
    test_error_detection
}

# Execute tests
main