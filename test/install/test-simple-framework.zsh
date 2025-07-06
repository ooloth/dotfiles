#!/usr/bin/env zsh

# Simple test to validate installation framework basics

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

# Test basic environment setup
test_basic_environment() {
    test_suite "Basic Installation Environment"
    
    test_case "Should set up test directories"
    
    setup_install_test_environment
    
    # Verify basic directories exist
    assert_directory_created "$INSTALL_TEST_HOME"
    assert_directory_created "$INSTALL_TEST_LOCAL"
    
    cleanup_install_test_environment
    
    test_suite_end
}

# Test basic mocking
test_basic_mocking() {
    test_suite "Basic Installation Mocking"
    
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should initialize mocking without errors"
    
    # Test simple command execution
    brew --version
    assert_command_called "brew --version"
    
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_basic_environment
    test_basic_mocking
}

# Execute tests
main