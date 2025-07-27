#!/usr/bin/env bats

# Tests for Zsh update script functionality
# Focuses on update-specific logic and validation

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

# Helper function to create mock brew command that handles updates
create_mock_brew_update() {
    local upgrade_behavior="${1:-success}"  # success, failure, or no-op
    
    mkdir -p "$TEST_TEMP_DIR/mock-bin"
    cat > "$TEST_TEMP_DIR/mock-bin/brew" << EOF
#!/bin/bash
case "\$1" in
    "upgrade")
        if [[ "\$2" == "zsh" ]]; then
            if [[ "$upgrade_behavior" == "success" ]]; then
                echo "==> Upgrading zsh 5.8 -> 5.9"
                exit 0
            elif [[ "$upgrade_behavior" == "failure" ]]; then
                echo "Error: Could not upgrade zsh"
                exit 1
            elif [[ "$upgrade_behavior" == "no-op" ]]; then
                echo "Warning: zsh 5.8 already installed"
                exit 1
            fi
        fi
        ;;
    "install")
        if [[ "\$2" == "zsh" ]]; then
            echo "==> Installing zsh 5.8"
            exit 0
        fi
        ;;
esac
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/mock-bin/brew"
    export PATH="$TEST_TEMP_DIR/mock-bin:$PATH"
}

# Helper function to create mock zsh installation
create_mock_zsh() {
    mkdir -p /tmp/mock-homebrew/bin
    cat > /tmp/mock-homebrew/bin/zsh << 'EOF'
#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "zsh 5.8 (x86_64-apple-darwin21.0)"
else
    echo "mock zsh shell"
fi
EOF
    chmod +x /tmp/mock-homebrew/bin/zsh
    
    # Also create it in system PATH for command -v checks
    mkdir -p "$TEST_TEMP_DIR/system-bin"
    cp /tmp/mock-homebrew/bin/zsh "$TEST_TEMP_DIR/system-bin/"
    export PATH="$TEST_TEMP_DIR/system-bin:$PATH"
}

@test "update handles successful zsh upgrade" {
    create_mock_zsh
    create_mock_brew_update "success"
    
    # Mock the utility functions for successful validation
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Zsh via Homebrew"* ]]
    [[ "$output" == *"Zsh updated via Homebrew"* ]]
}

@test "update handles brew upgrade failure gracefully" {
    create_mock_zsh
    create_mock_brew_update "failure"
    
    # Mock the utility functions
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]  # Should still succeed overall
    [[ "$output" == *"may have failed or Zsh was already up to date"* ]]
}

@test "update handles case when zsh already up to date" {
    create_mock_zsh
    create_mock_brew_update "no-op"
    
    # Mock the utility functions
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"may have failed or Zsh was already up to date"* ]]
}

@test "update fails when zsh not initially installed" {
    # Don't create mock zsh
    create_mock_brew_update "success"
    
    # Mock utility functions to simulate zsh not installed
    zsh_is_installed() { return 1; }
    homebrew_is_installed() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Zsh is not installed"* ]]
}

@test "update warns when homebrew not available" {
    create_mock_zsh
    # Don't create mock brew
    
    # Mock utility functions
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 1; }  # Homebrew not available
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Homebrew not available - cannot update Zsh"* ]]
}

@test "update re-validates shell configuration after update" {
    create_mock_zsh
    create_mock_brew_update "success"
    
    # Mock utility functions - simulate shell path issues after update
    local shells_check_count=0
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { 
        shells_check_count=$((shells_check_count + 1))
        return 0
    }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    add_zsh_to_shells() {
        print_success "Zsh path verified in /etc/shells"
        return 0
    }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Verifying Zsh configuration after update"* ]]
    [[ "$output" == *"Zsh path verified in /etc/shells"* ]]
}

@test "update warns when user shell needs reset" {
    create_mock_zsh
    create_mock_brew_update "success"
    
    # Mock utility functions - simulate user shell issue
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 1; }  # User shell is not zsh
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    add_zsh_to_shells() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"User shell may need to be reset to Zsh"* ]]
    [[ "$output" == *"sudo chsh -s"* ]]
}

@test "update shows version information after completion" {
    create_mock_zsh
    create_mock_brew_update "success"
    
    # Mock utility functions for successful validation
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { return 0; }
    validate_zsh_configuration() { return 0; }
    add_zsh_to_shells() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Zsh version:"* ]]
    [[ "$output" == *"Zsh location:"* ]]
    [[ "$output" == *"Current shell:"* ]]
}

@test "update handles validation failures gracefully" {
    create_mock_zsh
    create_mock_brew_update "success"
    
    # Mock utility functions - simulate validation failures
    zsh_is_installed() { return 0; }
    homebrew_is_installed() { return 0; }
    zsh_in_shells_file() { return 0; }
    user_shell_is_zsh() { return 0; }
    validate_zsh_installation() { 
        print_warning "Zsh installation validation had issues"
        return 1
    }
    validate_zsh_configuration() { 
        print_warning "Zsh configuration validation had issues"
        return 1
    }
    add_zsh_to_shells() { return 0; }
    
    # Source and test the update script main function
    source "$DOTFILES/../../../features/zsh/update.bash"
    
    run main
    [ "$status" -eq 0 ]  # Still succeeds despite validation warnings
    [[ "$output" == *"validation had issues"* ]]
}