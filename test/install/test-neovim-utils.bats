#!/usr/bin/env bats

# Test Neovim utility functions

# Load the Neovim utilities
load "../../lib/neovim-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    
    # Set test HOME
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "neovim_config_installed returns false when config not found" {
    run neovim_config_installed
    [ "$status" -eq 1 ]
}

@test "neovim_config_installed returns true when config exists" {
    mkdir -p "$HOME/Repos/ooloth/config.nvim"
    
    run neovim_config_installed
    [ "$status" -eq 0 ]
}

@test "clone_neovim_config clones the config repository" {
    # Create mock git
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    
    cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
echo "git $@"
if [[ "$1" == "clone" ]]; then
    # Get the last argument (target directory)
    for arg in "$@"; do
        target="$arg"
    done
    # Create the target directory to simulate successful clone
    mkdir -p "$target"
fi
EOF
    chmod +x "$mock_bin/git"
    
    PATH="$mock_bin:/usr/bin:/bin"
    
    run clone_neovim_config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing config.nvim" ]]
    [[ "$output" =~ "git clone" ]]
    [ -d "$HOME/Repos/ooloth/config.nvim" ]
}

@test "restore_neovim_plugins runs nvim headless command" {
    # Create mock nvim
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    local log_file="$TEST_TEMP_DIR/nvim.log"
    
    cat > "$mock_bin/nvim" << EOF
#!/bin/bash
echo "nvim \$@" > "$log_file"
EOF
    chmod +x "$mock_bin/nvim"
    
    PATH="$mock_bin:/usr/bin:/bin"
    
    run restore_neovim_plugins
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing Lazy plugin versions" ]]
    
    # Check nvim was called with correct args
    [[ -f "$log_file" ]]
    grep -q "headless" "$log_file"
    grep -q "Lazy! restore" "$log_file"
}