#!/usr/bin/env bats

# Integration tests for Zsh installation script
# Tests the complete workflow including error handling and system interactions

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
    export ORIGINAL_PATH="$PATH"
    
    # Set test environment
    export HOME="$TEST_TEMP_DIR"
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
    
    # Create mock dotfiles structure
    mkdir -p "$DOTFILES/features/zsh/config"
    
    # Create essential config files for testing
    touch "$DOTFILES/features/zsh/config/aliases.zsh"
    touch "$DOTFILES/features/zsh/config/options.zsh"
    touch "$DOTFILES/features/zsh/config/path.zsh"
    touch "$DOTFILES/features/zsh/config/plugins.zsh"
    touch "$DOTFILES/features/zsh/config/utils.zsh"
    touch "$DOTFILES/features/zsh/config/variables.zsh"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export SHELL="$ORIGINAL_SHELL"
    export PATH="$ORIGINAL_PATH"
    if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    # Clean up any mock directories
    [[ -d "/tmp/mock-homebrew" ]] && rm -rf "/tmp/mock-homebrew"
}

# Helper function to create mock zsh installation
create_mock_zsh() {
    mkdir -p /tmp/mock-homebrew/bin
    cat > /tmp/mock-homebrew/bin/zsh << 'EOF'
#!/bin/bash
echo "zsh 5.8 (x86_64-apple-darwin21.0)"
EOF
    chmod +x /tmp/mock-homebrew/bin/zsh
}

# Helper function to create mock brew command
create_mock_brew() {
    mkdir -p "$TEST_TEMP_DIR/mock-bin"
    cat > "$TEST_TEMP_DIR/mock-bin/brew" << 'EOF'
#!/bin/bash
case "$1" in
    "install")
        if [[ "$2" == "zsh" ]]; then
            echo "Installing zsh..."
            exit 0
        fi
        ;;
    "upgrade")
        if [[ "$2" == "zsh" ]]; then
            echo "Upgrading zsh..."
            exit 0
        fi
        ;;
esac
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/mock-bin/brew"
    PATH="$TEST_TEMP_DIR/mock-bin:/usr/bin:/bin"
}

@test "install_zsh_via_homebrew succeeds when brew is available" {
    create_mock_brew
    
    run install_zsh_via_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Zsh via Homebrew"* ]]
}

@test "install_zsh_via_homebrew fails when brew is not available" {
    # Ensure brew is not in PATH
    export PATH="/usr/bin:/bin"
    
    run install_zsh_via_homebrew
    [ "$status" -eq 1 ]
    [[ "$output" == *"Homebrew is required"* ]]
}

@test "add_zsh_to_shells adds zsh when not present" {
    # Create mock /etc/shells without zsh
    local mock_shells="$TEST_TEMP_DIR/shells"
    echo "/bin/bash" > "$mock_shells"
    echo "/bin/sh" >> "$mock_shells"
    
    # Mock the functions that interact with /etc/shells
    zsh_in_shells_file() { return 1; }  # Simulate zsh not in shells
    
    # Mock sudo and tee to capture the operation
    local captured_output="$TEST_TEMP_DIR/captured"
    sudo() {
        if [[ "$1" == "tee" ]]; then
            cat > "$captured_output"
        fi
    }
    tee() {
        cat > "$captured_output"
    }
    
    run add_zsh_to_shells "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Adding"* ]]
}

@test "add_zsh_to_shells skips when zsh already present" {
    # Mock the function to simulate zsh already in shells
    zsh_in_shells_file() { return 0; }  # Simulate zsh already in shells
    
    run add_zsh_to_shells "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
    # Should not output the "Adding" message
    [[ "$output" != *"Adding"* ]]
}

@test "change_user_shell_to_zsh changes shell when different" {
    export SHELL="/bin/bash"
    
    # Mock sudo and chsh
    local chsh_called=false
    sudo() {
        if [[ "$1" == "chsh" ]]; then
            chsh_called=true
        fi
    }
    chsh() {
        chsh_called=true
    }
    
    run change_user_shell_to_zsh "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Changing your shell"* ]]
}

@test "change_user_shell_to_zsh skips when already zsh" {
    export SHELL="/opt/homebrew/bin/zsh"
    
    run change_user_shell_to_zsh "/opt/homebrew/bin/zsh"
    [ "$status" -eq 0 ]
    # Should not output the "Changing" message
    [[ "$output" != *"Changing your shell"* ]]
}

@test "validate_zsh_installation passes with proper setup" {
    create_mock_zsh
    export SHELL="/tmp/mock-homebrew/bin/zsh"
    
    # Override the utility functions to use our mock
    get_zsh_shell_path() { echo "/tmp/mock-homebrew/bin/zsh"; }
    zsh_in_shells_file() { return 0; }  # Simulate zsh in shells
    
    run validate_zsh_installation "/tmp/mock-homebrew/bin/zsh"
    [ "$status" -eq 0 ]
}

@test "validate_zsh_installation fails when zsh not executable" {
    # Don't create the mock zsh executable
    
    run validate_zsh_installation "/nonexistent/zsh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found or not executable"* ]]
}

@test "validate_zsh_installation fails when zsh not in shells" {
    create_mock_zsh
    
    # Mock function to simulate zsh not in shells
    zsh_in_shells_file() { return 1; }
    
    run validate_zsh_installation "/tmp/mock-homebrew/bin/zsh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found in /etc/shells"* ]]
}

@test "validate_zsh_installation warns when user shell incorrect" {
    create_mock_zsh
    export SHELL="/bin/bash"  # Different from zsh path
    
    # Mock function to simulate zsh in shells
    zsh_in_shells_file() { return 0; }
    
    run validate_zsh_installation "/tmp/mock-homebrew/bin/zsh"
    [ "$status" -eq 0 ]  # Still passes but with warning
    [[ "$output" == *"User shell not set to Zsh"* ]]
}

@test "get_zsh_config_dir uses DOTFILES environment variable" {
    export DOTFILES="/custom/path/dotfiles"
    
    run get_zsh_config_dir
    [ "$status" -eq 0 ]
    [ "$output" = "/custom/path/dotfiles/config/zsh" ]
}

@test "get_zsh_config_dir falls back to default when DOTFILES unset" {
    unset DOTFILES
    
    run get_zsh_config_dir
    [ "$status" -eq 0 ]
    [ "$output" = "$HOME/Repos/ooloth/dotfiles/config/zsh" ]
}