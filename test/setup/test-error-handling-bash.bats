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

# Test capture_error with failing command
@test "capture_error handles failing command and provides context" {
    run capture_error "exit 42" "Test operation"
    [ "$status" -eq 42 ]
    [[ "$output" =~ "Error: Test operation failed (exit code: 42)" ]]
    [[ "$output" =~ "Command: exit 42" ]]
}

# Test capture_error preserves command output before showing error
@test "capture_error shows command output before error message" {
    run capture_error "echo 'Output before failure' && exit 1" "Command with output"
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" == "Output before failure" ]]
    [[ "$output" =~ "Error: Command with output failed" ]]
}

# Test retry_with_backoff with no command provided
@test "retry_with_backoff returns error when no command provided" {
    run retry_with_backoff
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No command provided to retry_with_backoff" ]]
}

# Test retry_with_backoff with successful command on first try
@test "retry_with_backoff succeeds on first attempt" {
    run retry_with_backoff "exit 0"
    [ "$status" -eq 0 ]
}

# Test retry_with_backoff exhausts all attempts and fails
@test "retry_with_backoff fails after exhausting max attempts" {
    run retry_with_backoff "exit 1" 2 0
    [ "$status" -eq 1 ]
}

# Test handle_error with no command provided
@test "handle_error returns error when no command provided" {
    run handle_error
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No command provided to handle_error" ]]
}

# Test handle_error displays error message and generic suggestion
@test "handle_error displays error message and generic suggestion" {
    run handle_error "test-command" "999" "Custom error message"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "❌ Error occurred while running: test-command" ]]
    [[ "$output" =~ "Error: Custom error message" ]]
    [[ "$output" =~ "💡 Suggestion: Check the command syntax and try again" ]]
}

# Test handle_error provides permission-specific suggestion
@test "handle_error provides permission-specific suggestion for EACCES" {
    run handle_error "test-command" "EACCES" "Permission denied"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "❌ Error occurred while running: test-command" ]]
    [[ "$output" =~ "Error: Permission denied" ]]
    [[ "$output" =~ "💡 Suggestion: Try running with sudo or check file permissions" ]]
}

# Test handle_error provides file-not-found suggestion
@test "handle_error provides file-not-found suggestion for ENOENT" {
    run handle_error "test-command" "ENOENT" "No such file or directory"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "❌ Error occurred while running: test-command" ]]
    [[ "$output" =~ "Error: No such file or directory" ]]
    [[ "$output" =~ "💡 Suggestion: Check if the file or directory exists" ]]
}

# Test handle_error provides network-specific suggestion
@test "handle_error provides network-specific suggestion for ECONNREFUSED" {
    run handle_error "test-command" "ECONNREFUSED" "Connection refused"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "❌ Error occurred while running: test-command" ]]
    [[ "$output" =~ "Error: Connection refused" ]]
    [[ "$output" =~ "💡 Suggestion: Check your internet connection or try again later" ]]
}

# Test handle_error provides disk-space suggestion
@test "handle_error provides disk-space suggestion for ENOSPC" {
    run handle_error "test-command" "ENOSPC" "No space left on device"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "❌ Error occurred while running: test-command" ]]
    [[ "$output" =~ "Error: No space left on device" ]]
    [[ "$output" =~ "💡 Suggestion: Free up disk space and try again" ]]
}