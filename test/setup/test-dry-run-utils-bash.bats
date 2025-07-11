#!/usr/bin/env bats

# Dry-run utilities tests (bash version)
# Tests the bash version of dry-run functionality

# Load the dry-run utilities
load "../../bin/lib/dry-run-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_DRY_RUN="${DRY_RUN:-}"
    
    # Clear dry-run environment variables for clean testing
    unset DRY_RUN
}

teardown() {
    # Restore original environment
    if [[ -n "$ORIGINAL_DRY_RUN" ]]; then
        export DRY_RUN="$ORIGINAL_DRY_RUN"
    else
        unset DRY_RUN
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Unit Tests for parse_dry_run_flags function

@test "parse_dry_run_flags sets DRY_RUN=true when --dry-run flag present" {
    # Function sets variables in current shell, don't use run
    parse_dry_run_flags "--dry-run"
    [ "$DRY_RUN" = "true" ]
}

@test "parse_dry_run_flags sets DRY_RUN=true when --dry-run is among multiple args" {
    # Function sets variables in current shell, don't use run
    parse_dry_run_flags "--verbose" "--dry-run" "--force"
    [ "$DRY_RUN" = "true" ]
}

@test "parse_dry_run_flags sets DRY_RUN=false when --dry-run flag not present" {
    # Function sets variables in current shell, don't use run
    parse_dry_run_flags "--verbose" "--force"
    [ "$DRY_RUN" = "false" ]
}

@test "parse_dry_run_flags sets DRY_RUN=false when no arguments provided" {
    # Function sets variables in current shell, don't use run
    parse_dry_run_flags
    [ "$DRY_RUN" = "false" ]
}

@test "parse_dry_run_flags handles empty string arguments" {
    # Function sets variables in current shell, don't use run
    parse_dry_run_flags "" "--dry-run" ""
    [ "$DRY_RUN" = "true" ]
}

# Unit Tests for dry_run_log function

@test "dry_run_log outputs action with DRY RUN prefix" {
    run dry_run_log "test action"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: test action" ]]
}

@test "dry_run_log handles multi-word actions" {
    run dry_run_log "install homebrew packages"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: install homebrew packages" ]]
}

@test "dry_run_log fails when no action provided" {
    run dry_run_log ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"No action provided to dry_run_log"* ]]
}

@test "dry_run_log fails when action is missing" {
    run dry_run_log
    [ "$status" -eq 1 ]
    [[ "$output" == *"No action provided to dry_run_log"* ]]
}

# Unit Tests for dry_run_execute function

@test "dry_run_execute logs command in dry-run mode" {
    export DRY_RUN="true"
    
    run dry_run_execute "echo 'test command'"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: echo 'test command'" ]]
}

@test "dry_run_execute executes command in normal mode" {
    export DRY_RUN="false"
    
    run dry_run_execute "echo 'actual output'"
    [ "$status" -eq 0 ]
    [[ "$output" == "actual output" ]]
}

@test "dry_run_execute executes command when DRY_RUN not set" {
    unset DRY_RUN
    
    run dry_run_execute "echo 'default behavior'"
    [ "$status" -eq 0 ]
    [[ "$output" == "default behavior" ]]
}

@test "dry_run_execute returns command exit code in normal mode" {
    export DRY_RUN="false"
    
    run dry_run_execute "exit 42"
    [ "$status" -eq 42 ]
}

@test "dry_run_execute returns 0 in dry-run mode regardless of command" {
    export DRY_RUN="true"
    
    run dry_run_execute "exit 42"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: exit 42" ]]
}

@test "dry_run_execute fails when no command provided" {
    run dry_run_execute ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"No command provided to dry_run_execute"* ]]
}

@test "dry_run_execute fails when command is missing" {
    run dry_run_execute
    [ "$status" -eq 1 ]
    [[ "$output" == *"No command provided to dry_run_execute"* ]]
}

# Integration Tests

@test "dry_run_execute with complex command in dry-run mode" {
    export DRY_RUN="true"
    
    run dry_run_execute "mkdir -p /tmp/test && echo 'directory created'"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: mkdir -p /tmp/test && echo 'directory created'" ]]
}

@test "dry_run_execute with complex command in normal mode" {
    export DRY_RUN="false"
    
    # Use test temp dir for actual execution
    run dry_run_execute "mkdir -p '$TEST_TEMP_DIR/test' && echo 'directory created'"
    [ "$status" -eq 0 ]
    [[ "$output" == "directory created" ]]
    # Verify directory was actually created
    [ -d "$TEST_TEMP_DIR/test" ]
}

@test "workflow integration: parse flags then execute commands" {
    # Parse --dry-run flag
    parse_dry_run_flags "--dry-run" "--verbose"
    
    # Verify dry-run mode was set
    [ "$DRY_RUN" = "true" ]
    
    # Execute commands in dry-run mode
    run dry_run_execute "echo 'first command'"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: echo 'first command'" ]]
    
    run dry_run_execute "mkdir /tmp/testdir"
    [ "$status" -eq 0 ]
    [[ "$output" == "DRY RUN: mkdir /tmp/testdir" ]]
}

@test "workflow integration: parse normal flags then execute commands" {
    # Parse flags without --dry-run
    parse_dry_run_flags "--verbose" "--force"
    
    # Verify normal mode was set
    [ "$DRY_RUN" = "false" ]
    
    # Execute commands in normal mode
    run dry_run_execute "echo 'actual execution'"
    [ "$status" -eq 0 ]
    [[ "$output" == "actual execution" ]]
}