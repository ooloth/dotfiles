#!/usr/bin/env bats

# Test Neovim utility functions
# Tests all utility functions in utils.bash

# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"

# Load testing helpers
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment variables for restoration
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    # Create fake dotfiles structure
    mkdir -p "$DOTFILES/features/neovim"
    cp "$BATS_TEST_DIRNAME/../utils.bash" "$DOTFILES/features/neovim/"
    
    # Source the utils for testing
    source "$DOTFILES/features/neovim/utils.bash"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export PATH="$ORIGINAL_PATH"
    export DOTFILES="$ORIGINAL_DOTFILES"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper function to create mock Neovim
setup_neovim_mock() {
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    # Create mock nvim
    cat > "$fake_bin/nvim" << 'EOF'
#!/bin/bash
case "$1" in
    --version) 
        echo "NVIM v0.9.5"
        echo "Build type: Release"
        echo "LuaJIT 2.1.0-beta3"
        ;;
    --headless) 
        # Mock headless execution for plugin restore
        if [[ "$*" == *"Lazy! restore"* ]]; then
            echo "Installing plugins..."
            echo "All plugins restored!"
        fi
        ;;
    *) echo "nvim: mock neovim" ;;
esac
exit 0
EOF
    chmod +x "$fake_bin/nvim"
    
    PATH="$fake_bin:/usr/bin:/bin"
}

# Helper function to create mock config repository
setup_neovim_config_mock() {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    mkdir -p "$config_dir"
    
    # Initialize as git repository
    cd "$config_dir"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create init.lua
    cat > init.lua << 'EOF'
-- Mock Neovim configuration
vim.g.mapleader = ' '
print("Mock config loaded")
EOF
    
    git add init.lua
    git commit --quiet -m "Initial commit"
    
    cd - > /dev/null
}

# Helper function to mock package managers
setup_package_manager_mocks() {
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    # Mock npm
    cat > "$fake_bin/npm" << 'EOF'
#!/bin/bash
case "$1" in
    install) echo "npm: installed $3" ;;
    *) echo "npm: mock npm" ;;
esac
exit 0
EOF
    chmod +x "$fake_bin/npm"
    
    # Mock brew
    cat > "$fake_bin/brew" << 'EOF'
#!/bin/bash
case "$1" in
    install) echo "brew: installed $2" ;;
    tap) echo "brew: tapped $2" ;;
    *) echo "brew: mock brew" ;;
esac
exit 0
EOF
    chmod +x "$fake_bin/brew"
    
    # Mock cargo
    cat > "$fake_bin/cargo" << 'EOF'
#!/bin/bash
case "$1" in
    install) echo "cargo: installed ${@:2}" ;;
    *) echo "cargo: mock cargo" ;;
esac
exit 0
EOF
    chmod +x "$fake_bin/cargo"
    
    PATH="$fake_bin:/usr/bin:/bin"
}

@test "command_exists returns 0 for existing commands" {
    run command_exists "bash"
    [ "$status" -eq 0 ]
}

@test "command_exists returns 1 for non-existing commands" {
    run command_exists "nonexistent_command_12345"
    [ "$status" -eq 1 ]
}

@test "command_exists returns 1 for empty command name" {
    run command_exists ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Command name is required"* ]]
}

@test "is_neovim_installed returns 0 when nvim is available" {
    setup_neovim_mock
    
    run is_neovim_installed
    [ "$status" -eq 0 ]
}

@test "is_neovim_installed returns 1 when nvim is not available" {
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run is_neovim_installed
    [ "$status" -eq 1 ]
}

@test "get_neovim_version returns version when nvim is available" {
    setup_neovim_mock
    
    run get_neovim_version
    [ "$status" -eq 0 ]
    [[ "$output" == *"NVIM v0.9.5"* ]]
}

@test "get_neovim_version returns error when nvim is not available" {
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run get_neovim_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"Neovim not installed"* ]]
}

@test "is_neovim_config_installed returns 0 when config directory exists with git" {
    setup_neovim_config_mock
    
    run is_neovim_config_installed
    [ "$status" -eq 0 ]
}

@test "is_neovim_config_installed returns 1 when config directory does not exist" {
    run is_neovim_config_installed
    [ "$status" -eq 1 ]
}

@test "is_neovim_config_installed returns 1 when config directory exists but is not git repo" {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    mkdir -p "$config_dir"
    
    run is_neovim_config_installed
    [ "$status" -eq 1 ]
}

@test "validate_neovim_config returns 0 for valid config" {
    setup_neovim_config_mock
    
    run validate_neovim_config
    [ "$status" -eq 0 ]
    [[ "$output" == *"Neovim config directory is valid"* ]]
}

@test "validate_neovim_config returns 1 when config directory missing" {
    run validate_neovim_config
    [ "$status" -eq 1 ]
    [[ "$output" == *"Neovim config directory not found"* ]]
}

@test "validate_neovim_config returns 1 when not a git repository" {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    mkdir -p "$config_dir"
    echo "-- mock init" > "$config_dir/init.lua"
    
    run validate_neovim_config
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a git repository"* ]]
}

@test "validate_neovim_config returns 1 when init.lua missing" {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    mkdir -p "$config_dir/.git"
    
    run validate_neovim_config
    [ "$status" -eq 1 ]
    [[ "$output" == *"init.lua not found"* ]]
}

@test "clone_neovim_config successfully clones repository" {
    # Mock git command
    git() {
        case "$1" in
            clone)
                local target_dir="$3"
                mkdir -p "$target_dir"
                cd "$target_dir"
                git init --quiet
                git config user.name "Test User"
                git config user.email "test@example.com"
                echo "-- cloned config" > init.lua
                git add init.lua
                git commit --quiet -m "Cloned commit"
                cd - > /dev/null
                echo "Cloning into '$target_dir'..."
                ;;
            *) command git "$@" ;;
        esac
    }
    export -f git
    
    run clone_neovim_config
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing config.nvim repository"* ]]
    [[ "$output" == *"config.nvim repository cloned successfully"* ]]
    
    # Verify directory was created
    [ -d "$HOME/Repos/ooloth/config.nvim" ]
    [ -f "$HOME/Repos/ooloth/config.nvim/init.lua" ]
}

@test "clone_neovim_config fails gracefully when git clone fails" {
    # Mock git to fail
    git() {
        case "$1" in
            clone) echo "fatal: repository not found"; return 1 ;;
            *) command git "$@" ;;
        esac
    }
    export -f git
    
    run clone_neovim_config
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to clone config.nvim repository"* ]]
}

@test "restore_neovim_plugins works when nvim is available" {
    setup_neovim_mock
    
    run restore_neovim_plugins
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Lazy plugin versions"* ]]
    [[ "$output" == *"Neovim plugins restored successfully"* ]]
}

@test "restore_neovim_plugins fails when nvim is not available" {
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run restore_neovim_plugins
    [ "$status" -eq 1 ]
    [[ "$output" == *"Neovim not found, cannot restore plugins"* ]]
}

@test "install_language_server works with npm packages" {
    setup_package_manager_mocks
    
    run install_language_server "TypeScript" "npm" "typescript"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing TypeScript language server: typescript"* ]]
    [[ "$output" == *"npm: installed typescript"* ]]
}

@test "install_language_server works with brew packages" {
    setup_package_manager_mocks
    
    run install_language_server "Lua" "brew" "lua-language-server"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Lua language server: lua-language-server"* ]]
    [[ "$output" == *"brew: installed lua-language-server"* ]]
}

@test "install_language_server works with cargo packages" {
    setup_package_manager_mocks
    
    run install_language_server "TOML" "cargo" "taplo-cli"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing TOML language server: taplo-cli"* ]]
    [[ "$output" == *"cargo: installed taplo-cli"* ]]
}

@test "install_language_server fails with unsupported package manager" {
    run install_language_server "Test" "unsupported" "package"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unsupported package manager: unsupported"* ]]
}

@test "install_language_server fails with missing arguments" {
    run install_language_server "Test" "npm"
    [ "$status" -eq 1 ]
    [[ "$output" == *"install_language_server requires: language, package_manager, package_name"* ]]
}

@test "validate_neovim_installation passes when everything is working" {
    setup_neovim_mock
    setup_neovim_config_mock
    
    run validate_neovim_installation
    [ "$status" -eq 0 ]
    [[ "$output" == *"Neovim is installed"* ]]
    [[ "$output" == *"Neovim version: NVIM v0.9.5"* ]]
    [[ "$output" == *"Neovim config repository is properly installed"* ]]
    [[ "$output" == *"Neovim installation validation passed"* ]]
}

@test "validate_neovim_installation fails when neovim is missing" {
    setup_neovim_config_mock
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run validate_neovim_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Neovim is not installed"* ]]
    [[ "$output" == *"Neovim installation validation failed"* ]]
}

@test "validate_neovim_installation fails when config is missing" {
    setup_neovim_mock
    
    run validate_neovim_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Neovim config repository is not installed"* ]]
    [[ "$output" == *"Neovim installation validation failed"* ]]
}