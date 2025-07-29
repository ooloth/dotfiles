#!/usr/bin/env bats

# Test Tmux utility functions

# Load the Tmux utilities
load "../../lib/tmux-utils.bash"

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

@test "tpm_installed returns false when TPM not found" {
    run tpm_installed
    [ "$status" -eq 1 ]
}

@test "tpm_installed returns true when TPM exists" {
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    
    run tpm_installed
    [ "$status" -eq 0 ]
}

@test "install_tpm clones TPM repository" {
    # Create mock git
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    
    cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
echo "git $@"
if [[ "$1" == "clone" ]]; then
    for arg in "$@"; do
        target="$arg"
    done
    mkdir -p "$target"
fi
EOF
    chmod +x "$mock_bin/git"
    
    PATH="$mock_bin:/usr/bin:/bin"
    
    run install_tpm
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing tpm" ]]
    [[ "$output" =~ "git clone" ]]
    [ -d "$HOME/.config/tmux/plugins/tpm" ]
}

@test "install_tpm_plugins runs install_plugins script" {
    # Create mock TPM directory and install script
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    mkdir -p "$tpm_dir/bin"
    
    cat > "$tpm_dir/bin/install_plugins" << 'EOF'
#!/bin/bash
echo "Installing TPM plugins..."
echo "Plugin 1 installed"
echo "Plugin 2 installed"
EOF
    chmod +x "$tpm_dir/bin/install_plugins"
    
    run install_tpm_plugins
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing tpm plugins" ]]
    [[ "$output" =~ "Plugin 1 installed" ]]
}