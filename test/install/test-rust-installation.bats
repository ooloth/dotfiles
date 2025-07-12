#!/usr/bin/env bats

# Test Rust installation script

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
    cp "lib/rust-utils.bash" "$DOTFILES/lib/"
    
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

@test "rust.bash exists and is executable" {
    [ -f "$(pwd)/bin/install/rust.bash" ]
    [ -x "$(pwd)/bin/install/rust.bash" ]
}

@test "rust.bash skips installation when rust is already installed" {
    # Create mock rustup command
    cat > "$MOCK_BIN/rustup" << 'EOF'
#!/bin/bash
echo "rustup 1.26.0"
EOF
    chmod +x "$MOCK_BIN/rustup"
    
    # Add mock bin to PATH
    PATH="$MOCK_BIN:$PATH"
    
    # Run rust installation
    run bash "$(pwd)/bin/install/rust.bash"
    
    # Should indicate rust is already installed
    [[ "$output" =~ "Rust is already installed" ]]
    [ "$status" -eq 0 ]
}

@test "rust.bash installs rust when not present" {
    # Create mock curl command that logs execution
    local install_log="$TEST_TEMP_DIR/install.log"
    cat > "$MOCK_BIN/curl" << EOF
#!/bin/bash
echo "curl executed with: \$@" > "$install_log"
# Mock the rustup script
cat << 'SCRIPT_EOF'
#!/bin/sh
echo "Mock rustup installer executed"
SCRIPT_EOF
EOF
    chmod +x "$MOCK_BIN/curl"
    
    # Create mock sh to capture installation
    cat > "$MOCK_BIN/sh" << 'EOF'
#!/bin/bash
echo "sh executed with rustup installer"
EOF
    chmod +x "$MOCK_BIN/sh"
    
    # Override PATH to exclude system rustup but keep essential commands
    PATH="$MOCK_BIN:/usr/bin:/bin"
    
    # Run rust installation
    run bash "$(pwd)/bin/install/rust.bash"
    
    # Should indicate installation is happening
    [[ "$output" =~ "Installing Rust toolchain" ]]
    [[ "$output" =~ "Finished installing rustup" ]]
    [ "$status" -eq 0 ]
    
    # Verify curl was called
    [[ -f "$install_log" ]]
}