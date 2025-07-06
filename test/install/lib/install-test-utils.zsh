#!/usr/bin/env zsh

# Installation script testing utilities
# Provides shared patterns and utilities for testing installation scripts

# Source base test utilities
source "$DOTFILES/test/lib/test-utils.zsh"

# Setup installation test environment
setup_install_test_environment() {
    # Set up base test environment
    setup_test_environment
    
    # Create installation-specific temp directories
    export INSTALL_TEST_HOMEBREW_DIR="$TEST_TEMP_DIR/homebrew"
    export INSTALL_TEST_SSH_DIR="$TEST_TEMP_DIR/ssh"
    export INSTALL_TEST_CONFIG_DIR="$TEST_TEMP_DIR/config"
    
    mkdir -p "$INSTALL_TEST_HOMEBREW_DIR"
    mkdir -p "$INSTALL_TEST_SSH_DIR"
    mkdir -p "$INSTALL_TEST_CONFIG_DIR"
    
    # Mock common installation directories
    export INSTALL_TEST_HOME="$TEST_TEMP_DIR/home"
    export INSTALL_TEST_LOCAL="$TEST_TEMP_DIR/usr/local"
    
    mkdir -p "$INSTALL_TEST_HOME/.ssh"
    mkdir -p "$INSTALL_TEST_HOME/.config"
    mkdir -p "$INSTALL_TEST_LOCAL/bin"
}

# Cleanup installation test environment
cleanup_install_test_environment() {
    cleanup_test_environment
    
    unset INSTALL_TEST_HOMEBREW_DIR
    unset INSTALL_TEST_SSH_DIR
    unset INSTALL_TEST_CONFIG_DIR
    unset INSTALL_TEST_HOME
    unset INSTALL_TEST_LOCAL
}

# Assert that a command was executed during installation
assert_command_executed() {
    local command="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="Command '$command' should have been executed"
    fi
    
    # Use the existing command tracking from mock.zsh
    assert_command_called "$command" "$message"
}

# Assert that a command was NOT executed during installation
assert_command_not_executed() {
    local command="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="Command '$command' should NOT have been executed"
    fi
    
    # Check if command was called and invert the assertion
    local mock_log="$MOCK_COMMAND_LOG"
    if [[ -f "$mock_log" ]] && grep -q "$command" "$mock_log"; then
        assert_false "true" "$message"
    else
        assert_true "true" "$message"
    fi
}

# Assert that a file was created during installation
assert_file_created() {
    local file_path="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="File '$file_path' should have been created"
    fi
    
    assert_file_exists "$file_path" "$message"
}

# Assert that a symlink was created during installation
assert_symlink_created() {
    local link_path="$1"
    local target_path="$2"
    local message="$3"
    
    if [[ -z "$message" ]]; then
        message="Symlink '$link_path' should point to '$target_path'"
    fi
    
    if [[ -L "$link_path" ]] && [[ "$(readlink "$link_path")" == "$target_path" ]]; then
        assert_true "true" "$message"
    else
        assert_false "true" "$message"
    fi
}

# Assert that a directory was created during installation
assert_directory_created() {
    local dir_path="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="Directory '$dir_path' should have been created"
    fi
    
    if [[ -d "$dir_path" ]]; then
        assert_true "true" "$message"
    else
        assert_false "true" "$message"
    fi
}

# Assert that an installation script completed successfully
assert_installation_successful() {
    local script_name="$1"
    local exit_code="$2"
    local message="$3"
    
    if [[ -z "$message" ]]; then
        message="Installation script '$script_name' should complete successfully"
    fi
    
    assert_equals "0" "$exit_code" "$message"
}

# Assert that an installation script failed appropriately
assert_installation_failed() {
    local script_name="$1"
    local exit_code="$2"
    local message="$3"
    
    if [[ -z "$message" ]]; then
        message="Installation script '$script_name' should fail when expected"
    fi
    
    assert_not_equals "0" "$exit_code" "$message"
}

# Run an installation script in test environment
run_install_script() {
    local script_path="$1"
    shift
    local args="$@"
    
    # Export test environment variables
    export HOME="$INSTALL_TEST_HOME"
    export HOMEBREW_PREFIX="$INSTALL_TEST_LOCAL"
    
    # Run the script and capture exit code
    local output
    local exit_code
    output=$(bash "$script_path" $args 2>&1)
    exit_code=$?
    
    # Store output for testing
    echo "$output" > "$TEST_TEMP_DIR/install_output.log"
    echo "$exit_code" > "$TEST_TEMP_DIR/install_exit_code.log"
    
    return $exit_code
}

# Get output from last installation script run
get_install_output() {
    if [[ -f "$TEST_TEMP_DIR/install_output.log" ]]; then
        cat "$TEST_TEMP_DIR/install_output.log"
    fi
}

# Get exit code from last installation script run
get_install_exit_code() {
    if [[ -f "$TEST_TEMP_DIR/install_exit_code.log" ]]; then
        cat "$TEST_TEMP_DIR/install_exit_code.log"
    else
        echo "1"
    fi
}

# Validate installation output contains expected messages
assert_install_output_contains() {
    local expected_text="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="Installation output should contain '$expected_text'"
    fi
    
    local output
    output=$(get_install_output)
    
    if echo "$output" | grep -q "$expected_text"; then
        assert_true "true" "$message"
    else
        assert_false "true" "$message"
    fi
}

# Validate installation output does NOT contain specific messages
assert_install_output_not_contains() {
    local unexpected_text="$1"
    local message="$2"
    
    if [[ -z "$message" ]]; then
        message="Installation output should NOT contain '$unexpected_text'"
    fi
    
    local output
    output=$(get_install_output)
    
    if echo "$output" | grep -q "$unexpected_text"; then
        assert_false "true" "$message"
    else
        assert_true "true" "$message"
    fi
}