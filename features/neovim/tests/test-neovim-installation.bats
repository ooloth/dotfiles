#!/usr/bin/env bats

# Test Neovim installation and update scripts
# Tests the main installation flow and update functionality

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
    cp "$BATS_TEST_DIRNAME/../install.bash" "$DOTFILES/features/neovim/"
    cp "$BATS_TEST_DIRNAME/../update.bash" "$DOTFILES/features/neovim/"
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
    
    export PATH="$fake_bin:$PATH"
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

# Helper function to mock git clone
setup_git_clone_mock() {
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
    
    export PATH="$fake_bin:$PATH"
}

@test "install script fails when Neovim is not installed" {
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Installing Neovim configuration"* ]]
    [[ "$output" == *"Neovim is not installed"* ]]
    [[ "$output" == *"Please install Neovim first"* ]]
}

@test "install script detects when config is already installed" {
    setup_neovim_mock
    setup_neovim_config_mock
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Neovim configuration"* ]]
    [[ "$output" == *"Found Neovim: NVIM v0.9.5"* ]]
    [[ "$output" == *"config.nvim is already installed"* ]]
    [[ "$output" == *"Neovim config repository is valid"* ]]
    [[ "$output" == *"Neovim setup completed"* ]]
}

@test "install script installs config when not present" {
    setup_neovim_mock
    setup_git_clone_mock
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Neovim configuration"* ]]
    [[ "$output" == *"config.nvim not found, proceeding with installation"* ]]
    [[ "$output" == *"Installing config.nvim repository"* ]]
    [[ "$output" == *"config.nvim repository installed successfully"* ]]
    [[ "$output" == *"Installing plugins"* ]]
    [[ "$output" == *"Finished installing Neovim configuration successfully"* ]]
}

@test "install script provides helpful next steps when installation succeeds" {
    setup_neovim_mock
    setup_git_clone_mock
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next steps:"* ]]
    [[ "$output" == *"Try opening Neovim: nvim"* ]]
    [[ "$output" == *"NVIM_APPNAME=nvim-ide"* ]]
    [[ "$output" == *"Lazy.nvim"* ]]
}

@test "install script validates configuration after installation" {
    setup_neovim_mock
    setup_git_clone_mock
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validating Neovim configuration"* ]]
    [[ "$output" == *"Neovim config repository validation passed"* ]]
    [[ "$output" == *"Final validation"* ]]
    [[ "$output" == *"Complete Neovim installation validation passed"* ]]
}

@test "install script fails gracefully when git clone fails" {
    setup_neovim_mock
    
    # Mock git to fail
    git() {
        case "$1" in
            clone) echo "fatal: repository not found"; return 1 ;;
            *) command git "$@" ;;
        esac
    }
    export -f git
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install config.nvim repository"* ]]
}

@test "install script fails gracefully when plugin restoration fails" {
    setup_git_clone_mock
    
    # Mock nvim to fail on plugin restore
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    cat > "$fake_bin/nvim" << 'EOF'
#!/bin/bash
case "$1" in
    --version) 
        echo "NVIM v0.9.5"
        ;;
    --headless) 
        if [[ "$*" == *"Lazy! restore"* ]]; then
            echo "Error: Failed to restore plugins"
            exit 1
        fi
        ;;
    *) echo "nvim: mock neovim" ;;
esac
exit 0
EOF
    chmod +x "$fake_bin/nvim"
    export PATH="$fake_bin:$PATH"
    
    run bash "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install Neovim plugins"* ]]
}

@test "update script fails when Neovim is not installed" {
    # Ensure nvim is not in PATH
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Updating Neovim configuration"* ]]
    [[ "$output" == *"Neovim is not installed"* ]]
    [[ "$output" == *"Please install Neovim first"* ]]
}

@test "update script installs config when not present" {
    setup_neovim_mock
    setup_git_clone_mock
    setup_package_manager_mocks
    
    run bash "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Neovim configuration"* ]]
    [[ "$output" == *"Neovim config repository is not installed"* ]]
    [[ "$output" == *"Installing configuration first"* ]]
    [[ "$output" == *"Neovim config repository installed successfully"* ]]
}

@test "update script updates existing installation" {
    setup_neovim_mock
    setup_neovim_config_mock
    setup_package_manager_mocks
    
    run bash "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Neovim configuration"* ]]
    [[ "$output" == *"Current Neovim: NVIM v0.9.5"* ]]
    [[ "$output" == *"Neovim config repository is installed"* ]]
    [[ "$output" == *"Installing/updating language servers"* ]]
    [[ "$output" == *"Updating Neovim plugins"* ]]
    [[ "$output" == *"Neovim update completed successfully"* ]]
}

@test "update script provides helpful summary" {
    setup_neovim_mock
    setup_neovim_config_mock
    setup_package_manager_mocks
    
    run bash "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Summary of updates:"* ]]
    [[ "$output" == *"Language servers and development tools"* ]]
    [[ "$output" == *"Neovim plugins restored from lazy-lock.json"* ]]
    [[ "$output" == *"Next steps:"* ]]
    [[ "$output" == *":checkhealth"* ]]
}

@test "update script continues when some language servers fail" {
    setup_neovim_mock
    setup_neovim_config_mock
    
    # Mock package managers to fail for some packages
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    cat > "$fake_bin/npm" << 'EOF'
#!/bin/bash
if [[ "$*" == *"typescript"* ]]; then
    echo "npm: failed to install typescript"
    exit 1
else
    echo "npm: installed $3"
fi
exit 0
EOF
    chmod +x "$fake_bin/npm"
    
    cat > "$fake_bin/brew" << 'EOF'
#!/bin/bash
echo "brew: installed $2"
exit 0
EOF
    chmod +x "$fake_bin/brew"
    
    export PATH="$fake_bin:$PATH"
    
    run bash "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Some language servers or tools failed to install/update"* ]]
    [[ "$output" == *"Continuing with plugin update"* ]]
    [[ "$output" == *"Neovim update completed successfully"* ]]
}

@test "scripts can be executed directly without sourcing" {
    setup_neovim_mock
    setup_neovim_config_mock
    setup_package_manager_mocks
    
    # Test install script
    run "$DOTFILES/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    
    # Test update script
    run "$DOTFILES/features/neovim/update.bash"
    [ "$status" -eq 0 ]
}

@test "scripts handle missing DOTFILES environment variable" {
    setup_neovim_mock
    setup_neovim_config_mock
    
    # Clear DOTFILES and test default fallback
    unset DOTFILES
    
    # Update the script path in the copied files to use relative path
    sed -i '' 's|source "$DOTFILES/features/neovim/utils.bash"|source "$(dirname "$0")/utils.bash"|' "$TEST_TEMP_DIR/fake_dotfiles/features/neovim/install.bash"
    
    run bash "$TEST_TEMP_DIR/fake_dotfiles/features/neovim/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Neovim configuration"* ]]
}