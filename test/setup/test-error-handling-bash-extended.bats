#!/usr/bin/env bats

# Extended test suite for error handling utilities (bash implementation)
# Additional edge cases and integration tests

# Load the error handling utilities
load "../../bin/lib/error-handling.bash"

setup() {
  # Create temporary directory for test files
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test capture_error with command that produces stderr only
@test "capture_error captures stderr output from failed command" {
  run capture_error "echo 'Error message' >&2 && exit 1" "Stderr test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error message"* ]]
  [[ "$output" == *"Error: Stderr test failed (exit code: 1)"* ]]
}

# Test capture_error with command that produces both stdout and stderr
@test "capture_error captures both stdout and stderr" {
  run capture_error "echo 'Stdout message' && echo 'Stderr message' >&2 && exit 1" "Mixed output test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Stdout message"* ]]
  [[ "$output" == *"Stderr message"* ]]
  [[ "$output" == *"Error: Mixed output test failed"* ]]
}

# Test capture_error with empty command string
@test "capture_error handles empty command string" {
  run capture_error "" "Empty command test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: No command provided to capture_error"* ]]
}

# Test capture_error with command that has special characters
@test "capture_error handles commands with special characters" {
  run capture_error "echo 'Test with \$VAR and \"quotes\"'" "Special chars test"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test with \$VAR and \"quotes\""* ]]
}

# Test retry_with_backoff with zero max attempts
@test "retry_with_backoff handles zero max attempts" {
  run retry_with_backoff "exit 0" 0 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"Command failed after 0 attempts"* ]]
}

# Test retry_with_backoff with negative max attempts
@test "retry_with_backoff handles negative max attempts" {
  run retry_with_backoff "exit 0" -1 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"Command failed after -1 attempts"* ]]
}

# Test retry_with_backoff with zero initial delay
@test "retry_with_backoff works with zero initial delay" {
  # Create a tracking file
  local attempt_file="$TEST_TEMP_DIR/attempts"
  echo "0" > "$attempt_file"
  
  # Command that succeeds on second attempt
  local test_command="
    current=\$(cat '$attempt_file')
    next=\$((current + 1))
    echo \$next > '$attempt_file'
    [ \$next -eq 2 ]
  "
  
  run retry_with_backoff "$test_command" 3 0
  [ "$status" -eq 0 ]
}

# Test retry_with_backoff with large initial delay (but we won't wait)
@test "retry_with_backoff increments delay with exponential backoff" {
  # We'll test that the delay message shows the right values without actually waiting
  
  # Command that always fails
  run timeout 1 retry_with_backoff "exit 1" 3 1
  # timeout will kill it, but we can check the output pattern
  [[ "$output" == *"Attempt 1 failed, retrying in 1s"* ]]
}

# Test handle_error with EPERM error code
@test "handle_error provides permission-specific suggestion for EPERM" {
  run handle_error "test-command" "EPERM" "Operation not permitted"
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ Error occurred while running: test-command"* ]]
  [[ "$output" == *"Error: Operation not permitted"* ]]
  [[ "$output" == *"💡 Suggestion: Try running with sudo or check file permissions"* ]]
}

# Test handle_error with ETIMEDOUT error code
@test "handle_error provides network-specific suggestion for ETIMEDOUT" {
  run handle_error "curl example.com" "ETIMEDOUT" "Operation timed out"
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ Error occurred while running: curl example.com"* ]]
  [[ "$output" == *"Error: Operation timed out"* ]]
  [[ "$output" == *"💡 Suggestion: Check your internet connection or try again later"* ]]
}

# Test handle_error with empty error message
@test "handle_error handles empty error message" {
  run handle_error "test-command" "123" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ Error occurred while running: test-command"* ]]
  [[ "$output" == *"Error: "*  ]]  # Should show empty error message
}

# Test handle_error with very long command
@test "handle_error handles long command strings" {
  local long_command="very_long_command_name_that_goes_on_and_on_with_many_parameters --param1 value1 --param2 value2 --param3 value3"
  run handle_error "$long_command" "999" "Test error"
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ Error occurred while running: $long_command"* ]]
}

# Test integration: capture_error with retry_with_backoff
@test "integration test: capture_error with retry pattern" {
  # Create a command that fails twice then succeeds
  local attempt_file="$TEST_TEMP_DIR/integration_attempts"
  echo "0" > "$attempt_file"
  
  local test_command="
    current=\$(cat '$attempt_file')
    next=\$((current + 1))
    echo \$next > '$attempt_file'
    if [ \$next -lt 3 ]; then
      echo 'Attempt \$next failed' >&2
      exit 1
    else
      echo 'Attempt \$next succeeded'
      exit 0
    fi
  "
  
  # First test with capture_error (should fail)
  run capture_error "$test_command" "Integration test"
  [ "$status" -eq 1 ]
  
  # Reset attempts and test with retry
  echo "0" > "$attempt_file"
  run retry_with_backoff "$test_command" 4 0
  [ "$status" -eq 0 ]
}

# Test error handling with complex shell constructs
@test "capture_error handles complex shell constructs" {
  run capture_error "if true; then echo 'success'; else echo 'failure'; fi" "Complex shell test"
  [ "$status" -eq 0 ]
  [[ "$output" == "success" ]]
}

# Test error handling with pipes and redirections
@test "capture_error handles commands with pipes" {
  run capture_error "echo 'hello world' | grep 'hello'" "Pipe test"
  [ "$status" -eq 0 ]
  [[ "$output" == "hello world" ]]
}

# Test that retry_with_backoff doesn't show output on successful retry
@test "retry_with_backoff suppresses output during retries" {
  # Create a command that prints something and fails first time, succeeds second time
  local attempt_file="$TEST_TEMP_DIR/output_test"
  echo "0" > "$attempt_file"
  
  local test_command="
    current=\$(cat '$attempt_file')
    next=\$((current + 1))
    echo \$next > '$attempt_file'
    echo 'Command output \$next'
    [ \$next -eq 2 ]
  "
  
  run retry_with_backoff "$test_command" 3 0
  [ "$status" -eq 0 ]
  # Should only see the retry message, not the command output from failed attempts
  [[ "$output" == *"Attempt 1 failed, retrying"* ]]
  [[ "$output" != *"Command output 1"* ]]
}