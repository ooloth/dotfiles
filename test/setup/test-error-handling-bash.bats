#!/usr/bin/env bats

# Test error handling utilities (bash implementation)

# Load the error handling utilities
load "../../bin/lib/error-handling.bash"

# Test capture_error with no command provided
@test "capture_error returns error when no command provided" {
    run capture_error
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No command provided to capture_error" ]]
}

# Test capture_error with successful command
@test "capture_error executes successful command and returns 0" {
    run capture_error "echo 'Hello World'"
    [ "$status" -eq 0 ]
    [[ "$output" == "Hello World" ]]
}