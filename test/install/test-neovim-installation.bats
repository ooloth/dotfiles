#!/usr/bin/env bats

# Test Neovim installation script

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
    cp "lib/neovim-utils.bash" "$DOTFILES/lib/"
    
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

@test "neovim.bash exists and is executable" {
    [ -f "$(pwd)/bin/install/neovim.bash" ]
    [ -x "$(pwd)/bin/install/neovim.bash" ]
}

@test "neovim.bash skips installation when config already exists" {
    # Create config directory
    mkdir -p "$HOME/Repos/ooloth/config.nvim"
    
    run bash "$(pwd)/bin/install/neovim.bash"
    
    [[ "$output" =~ "config.nvim is already installed" ]]
    [ "$status" -eq 0 ]
}

@test "neovim.bash clones config and restores plugins when not present" {
    # Create mock git and nvim
    cat > "$MOCK_BIN/git" << 'EOF'
#!/bin/bash
echo "git $@"
if [[ "$1" == "clone" ]]; then
    for arg in "$@"; do
        target="$arg"
    done
    mkdir -p "$target"
fi
EOF
    chmod +x "$MOCK_BIN/git"
    
    cat > "$MOCK_BIN/nvim" << 'EOF'
#!/bin/bash
echo "nvim $@"
EOF
    chmod +x "$MOCK_BIN/nvim"
    
    PATH="$MOCK_BIN:$PATH"
    
    run bash "$(pwd)/bin/install/neovim.bash"
    
    [[ "$output" =~ "Installing config.nvim" ]]
    [[ "$output" =~ "git clone" ]]
    [[ "$output" =~ "Installing Lazy plugin versions" ]]
    [[ "$output" =~ "nvim --headless" ]]
    [ "$status" -eq 0 ]
    [ -d "$HOME/Repos/ooloth/config.nvim" ]
}