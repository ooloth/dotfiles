#!/usr/bin/env zsh

# Test setup.zsh integration with prerequisite validation
# This tests that setup.zsh properly handles prerequisite validation behavior

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Test setup.zsh prerequisite integration
test_setup_prerequisite_integration() {
    test_suite "Setup.zsh Prerequisite Integration"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should source prerequisite validation utilities"
    local setup_file="$ORIGINAL_DOTFILES/setup.zsh"
    
    assert_file_exists "$setup_file" "setup.zsh should exist"
    
    # Test that setup.zsh sources prerequisite validation
    if grep -q "prerequisite-validation.zsh" "$setup_file"; then
        assert_true "true" "setup.zsh should source prerequisite validation utilities"
    else
        assert_false "true" "setup.zsh should source prerequisite validation utilities"
    fi
    
    # Test that setup.zsh sources error handling utilities  
    if grep -q "error-handling.zsh" "$setup_file"; then
        assert_true "true" "setup.zsh should source error handling utilities"
    else
        assert_false "true" "setup.zsh should source error handling utilities"
    fi
    
    # Test that setup.zsh sources dry-run utilities
    if grep -q "dry-run-utils.zsh" "$setup_file"; then
        assert_true "true" "setup.zsh should source dry-run utilities"
    else
        assert_false "true" "setup.zsh should source dry-run utilities"
    fi
    
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_setup_prerequisite_integration
}

# Execute tests
main