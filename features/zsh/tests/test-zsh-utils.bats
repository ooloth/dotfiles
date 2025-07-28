#!/usr/bin/env bats

# Unit tests for Zsh utility functions
# Tests individual utility functions in isolation

# Load test helper functions
load "../../../test/lib/test-helper.bash"

# Load the utils we're testing
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    export ORIGINAL_SHELL="$SHELL"
    
    # Set test environment
    export HOME="$TEST_TEMP_DIR"
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export SHELL="$ORIGINAL_SHELL"
    if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "get_zsh_shell_path returns correct path" {
    run get_zsh_shell_path
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/homebrew/bin/zsh" ]
}

@test "zsh_is_installed detects existing zsh installation" {
    # Create mock zsh executable
    mkdir -p /tmp/mock-homebrew/bin
    echo "#!/bin/bash" > /tmp/mock-homebrew/bin/zsh
    chmod +x /tmp/mock-homebrew/bin/zsh
    
    # Override the function to use our mock path
    get_zsh_shell_path() { echo "/tmp/mock-homebrew/bin/zsh"; }
    
    run zsh_is_installed
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -rf /tmp/mock-homebrew
}

@test "zsh_is_installed returns false when zsh not found" {
    # Override to point to non-existent path
    get_zsh_shell_path() { echo "/nonexistent/zsh"; }
    
    run zsh_is_installed
    [ "$status" -eq 1 ]
}

@test "zsh_in_shells_file detects zsh in /etc/shells" {
    # Create mock /etc/shells
    local mock_shells="$TEST_TEMP_DIR/shells"
    echo "/bin/bash" > "$mock_shells"
    echo "/opt/homebrew/bin/zsh" >> "$mock_shells"
    echo "/bin/zsh" >> "$mock_shells"
    
    # Override grep to use our mock file
    grep() {
        if [[ "$*" == *"/etc/shells"* ]]; then
            command grep "$@" "$mock_shells"
        else
            command grep "$@"
        fi
    }
    
    run zsh_in_shells_file "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
}

@test "zsh_in_shells_file returns false when zsh not in shells" {
    # Create mock /etc/shells without zsh
    local mock_shells="$TEST_TEMP_DIR/shells"
    echo "/bin/bash" > "$mock_shells"
    echo "/bin/sh" >> "$mock_shells"
    
    # Override grep to use our mock file
    grep() {
        if [[ "$*" == *"/etc/shells"* ]]; then
            command grep "$@" "$mock_shells"
        else
            command grep "$@"
        fi
    }
    
    run zsh_in_shells_file "/opt/homebrew/bin/zsh"
    [ "$status" -eq 1 ]
}

@test "user_shell_is_zsh detects correct shell" {
    export SHELL="/opt/homebrew/bin/zsh"
    
    run user_shell_is_zsh "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
}

@test "user_shell_is_zsh returns false for different shell" {
    export SHELL="/bin/bash"
    
    run user_shell_is_zsh "/opt/homebrew/bin/zsh"
    [ "$status" -eq 1 ]
}

@test "homebrew_is_installed detects brew command" {
    # Create mock brew command
    mkdir -p "$TEST_TEMP_DIR/bin"
    echo "#!/bin/bash" > "$TEST_TEMP_DIR/bin/brew"
    chmod +x "$TEST_TEMP_DIR/bin/brew"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
    
    run homebrew_is_installed
    [ "$status" -eq 0 ]
}

@test "homebrew_is_installed returns false when brew not found" {
    # Remove brew from PATH
    export PATH="/usr/bin:/bin"
    
    run homebrew_is_installed
    [ "$status" -eq 1 ]
}

@test "get_zsh_config_dir returns correct path" {
    export DOTFILES="/custom/dotfiles"
    
    run get_zsh_config_dir
    [ "$status" -eq 0 ]
    [ "$output" = "/custom/dotfiles/config/zsh" ]
}

@test "zsh_config_exists detects existing config directory" {
    # Create config directory
    mkdir -p "$DOTFILES/config/zsh"
    
    run zsh_config_exists
    [ "$status" -eq 0 ]
}

@test "zsh_config_exists returns false when config missing" {
    # Don't create the config directory
    
    run zsh_config_exists
    [ "$status" -eq 1 ]
}

@test "validate_zsh_configuration checks essential files" {
    # Create config directory with some essential files
    mkdir -p "$DOTFILES/config/zsh"
    touch "$DOTFILES/config/zsh/aliases.zsh"
    touch "$DOTFILES/config/zsh/options.zsh"
    touch "$DOTFILES/config/zsh/path.zsh"
    touch "$DOTFILES/config/zsh/plugins.zsh"
    touch "$DOTFILES/config/zsh/utils.zsh"
    touch "$DOTFILES/config/zsh/variables.zsh"
    
    run validate_zsh_configuration
    [ "$status" -eq 0 ]
}

@test "validate_zsh_configuration warns about missing files" {
    # Create config directory but only some files
    mkdir -p "$DOTFILES/config/zsh"
    touch "$DOTFILES/config/zsh/aliases.zsh"
    # Missing other essential files
    
    run validate_zsh_configuration
    [ "$status" -eq 0 ]  # Still returns success but with warnings
    [[ "$output" == *"Missing Zsh configuration files"* ]]
}

@test "validate_zsh_configuration fails when config dir missing" {
    # Don't create config directory
    
    run validate_zsh_configuration
    [ "$status" -eq 1 ]
    [[ "$output" == *"configuration directory not found"* ]]
}

@test "print functions output consistent format" {
    run print_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "ℹ️  test message" ]]
    
    run print_success "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "✅ test message" ]]
    
    run print_warning "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "⚠️  test message" ]]
    
    run print_error "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "❌ test message" ]]
}