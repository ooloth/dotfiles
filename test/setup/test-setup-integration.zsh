#!/usr/bin/env zsh

# Test setup.zsh integration with prerequisite validation
# This tests that setup.zsh properly integrates prerequisite checks

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
    
    test_case "Should source prerequisite validation module"
    local setup_file="$ORIGINAL_DOTFILES/setup.zsh"
    
    assert_file_exists "$setup_file" "setup.zsh should exist"
    
    # Check that setup.zsh sources the prerequisite validation module
    if grep -q "prerequisite-validation.zsh" "$setup_file"; then
        assert_true "true" "setup.zsh sources prerequisite validation module"
    else
        assert_false "true" "setup.zsh should source prerequisite validation module"
    fi
    
    # Check that setup.zsh calls the validation function
    if grep -q "run_prerequisite_validation" "$setup_file"; then
        assert_true "true" "setup.zsh calls run_prerequisite_validation"
    else
        assert_false "true" "setup.zsh should call run_prerequisite_validation"
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