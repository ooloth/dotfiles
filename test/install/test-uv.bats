#!/usr/bin/env bats

# Test UV installation script

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"
    
    # Set up test environment
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
    mkdir -p "$DOTFILES/lib" "$DOTFILES/bin/install"
    
    # Copy the scripts we need
    cp "$ORIGINAL_DOTFILES/lib/uv-utils.bash" "$DOTFILES/lib/"
    cp "$ORIGINAL_DOTFILES/bin/install/uv.bash" "$DOTFILES/bin/install/"
    chmod +x "$DOTFILES/bin/install/uv.bash"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    export DOTFILES="$ORIGINAL_DOTFILES"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "uv installation script skips when UV already installed" {
    # Create mock uv command
    cat > "$MOCK_BIN/uv" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/uv"
    
    # Add mock bin to PATH
    PATH="$MOCK_BIN:/usr/bin:/bin"
    
    run "$DOTFILES/bin/install/uv.bash"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "UV is already installed" ]]
}

@test "uv installation script installs UV when not present" {
    # Create mock brew command that will also create uv
    cat > "$MOCK_BIN/brew" << EOF
#!/bin/bash
if [[ "\$1" == "install" && "\$2" == "uv" ]]; then
    echo "Installing uv..."
    # Create the uv command after installation
    cat > "$MOCK_BIN/uv" << 'UVEOF'
#!/bin/bash
if [[ "\$1" == "--version" ]]; then
    echo "uv 0.1.35"
fi
UVEOF
    chmod +x "$MOCK_BIN/uv"
fi
EOF
    chmod +x "$MOCK_BIN/brew"
    
    # Do NOT create uv command initially - should be missing
    
    # Add mock bin to PATH
    PATH="$MOCK_BIN:/usr/bin:/bin"
    
    run "$DOTFILES/bin/install/uv.bash"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing UV" ]]
    [[ "$output" =~ "Finished installing uv 0.1.35" ]]
}