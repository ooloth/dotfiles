#!/usr/bin/env zsh

# Test dry-run mode functionality
# This tests that setup.zsh can run in read-only mode for validation

# Store original DOTFILES path before any test setup modifies it
ORIGINAL_DOTFILES="$DOTFILES"

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

# Test dry-run flag parsing
test_dry_run_flag_parsing() {
    test_suite "Dry-Run Flag Parsing"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should parse --dry-run flag"
    
    # Source the dry-run utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
    
    # Test parsing --dry-run flag
    parse_dry_run_flags "--dry-run"
    assert_equals "true" "$DRY_RUN" "Should set DRY_RUN=true when --dry-run flag is passed"
    
    # Test parsing without flag
    unset DRY_RUN
    parse_dry_run_flags
    assert_equals "false" "$DRY_RUN" "Should set DRY_RUN=false when no flag is passed"
    
    # Test parsing with other arguments
    unset DRY_RUN
    parse_dry_run_flags "some-other-arg" "--dry-run" "another-arg"
    assert_equals "true" "$DRY_RUN" "Should set DRY_RUN=true when --dry-run flag is present among other arguments"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test dry-run logging functionality
test_dry_run_logging() {
    test_suite "Dry-Run Logging"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should log actions without executing in dry-run mode"
    
    # Source the dry-run utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
    
    # Set dry-run mode
    export DRY_RUN="true"
    
    # Test logging a dry-run action
    local output
    output=$(dry_run_log "mkdir test-directory" 2>&1)
    
    # Check that it logged the action
    if echo "$output" | grep -q "DRY RUN: mkdir test-directory"; then
        assert_true "true" "Should log dry-run actions with DRY RUN prefix"
    else
        assert_false "true" "Should log dry-run actions with DRY RUN prefix"
    fi
    
    # Test that it doesn't execute the actual command
    assert_false "test -d test-directory" "Should not actually create directory in dry-run mode"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Test conditional execution based on dry-run mode
test_conditional_execution() {
    test_suite "Conditional Execution"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should execute commands normally when not in dry-run mode"
    
    # Source the dry-run utilities module
    source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
    
    # Set normal mode
    export DRY_RUN="false"
    
    # Test conditional execution
    local output
    output=$(dry_run_execute "echo 'test execution'" 2>&1)
    
    # Check that it executed and returned output
    if echo "$output" | grep -q "test execution"; then
        assert_true "true" "Should execute commands normally when DRY_RUN=false"
    else
        assert_false "true" "Should execute commands normally when DRY_RUN=false"
    fi
    
    test_case "Should log without executing when in dry-run mode"
    
    # Re-source the module and set dry-run mode
    source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
    export DRY_RUN="true"
    
    # Test conditional execution in a way that preserves the environment
    local output
    (
        export DRY_RUN="true"
        source "$ORIGINAL_DOTFILES/bin/lib/dry-run-utils.zsh"
        dry_run_execute "echo 'test execution'" 2>&1
    ) > "$TEST_TEMP_DIR/dry_run_output"
    output=$(cat "$TEST_TEMP_DIR/dry_run_output")
    
    # Check that it logged but didn't execute
    if echo "$output" | grep -q "DRY RUN: echo 'test execution'"; then
        assert_true "true" "Should log commands when DRY_RUN=true"
    else
        assert_false "true" "Should log commands when DRY_RUN=true"
    fi
    
    # Should not contain the actual execution output (just "test execution" without "DRY RUN:")
    if echo "$output" | grep -v "DRY RUN:" | grep -q "test execution"; then
        assert_false "true" "Should not execute commands when DRY_RUN=true"
    else
        assert_true "true" "Should not execute commands when DRY_RUN=true"
    fi
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run all tests
main() {
    test_dry_run_flag_parsing
    test_dry_run_logging
    test_conditional_execution
}

# Execute tests
main