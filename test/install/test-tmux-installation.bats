#!/usr/bin/env bats

# Test Tmux installation script

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    export ORIGINAL_PATH="$PATH"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    # Create fake dotfiles structure
    mkdir -p "$DOTFILES/lib"
    cp "lib/tmux-utils.bash" "$DOTFILES/lib/"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
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
}

@test "tmux.bash exists and is executable" {
    [ -f "$(pwd)/bin/install/tmux.bash" ]
    [ -x "$(pwd)/bin/install/tmux.bash" ]
}

@test "tmux.bash skips TPM installation when already installed" {
    # Create TPM directory
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    mkdir -p "$tpm_dir/bin"
    
    # Create mock install_plugins script
    cat > "$tpm_dir/bin/install_plugins" << 'EOF'
#!/bin/bash
echo "Installing plugins..."
EOF
    chmod +x "$tpm_dir/bin/install_plugins"
    
    run bash "$(pwd)/bin/install/tmux.bash"
    
    [[ "$output" =~ "tpm is already installed" ]]
    [[ "$output" =~ "Installing tpm plugins" ]]
    [ "$status" -eq 0 ]
}

@test "tmux.bash installs TPM and plugins when not present" {
    # Create mock git
    cat > "$MOCK_BIN/git" << 'EOF'
#!/bin/bash
echo "git $@"
if [[ "$1" == "clone" ]]; then
    for arg in "$@"; do
        target="$arg"
    done
    mkdir -p "$target/bin"
    # Create mock install_plugins script
    cat > "$target/bin/install_plugins" << 'SCRIPT'
#!/bin/bash
echo "Installing plugins from fresh TPM..."
SCRIPT
    chmod +x "$target/bin/install_plugins"
fi
EOF
    chmod +x "$MOCK_BIN/git"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run bash "$(pwd)/bin/install/tmux.bash"
    
    [[ "$output" =~ "Installing tpm" ]]
    [[ "$output" =~ "git clone" ]]
    [[ "$output" =~ "Installing tpm plugins" ]]
    [[ "$output" =~ "Installing plugins from fresh TPM" ]]
    [[ "$output" =~ "Finished installing tmux" ]]
    [ "$status" -eq 0 ]
}