#!/usr/bin/env bats

# Test Node.js installation script

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
    cp "lib/node-utils.bash" "$DOTFILES/lib/"
    
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

@test "node.bash exists and is executable" {
    [ -f "$(pwd)/bin/install/node.bash" ]
    [ -x "$(pwd)/bin/install/node.bash" ]
}

@test "node.bash skips installation when latest version already installed" {
    # Create mock fnm with latest version installed
    cat > "$MOCK_BIN/fnm" << 'EOF'
#!/bin/bash
case "$1" in
    "ls-remote")
        echo "v21.5.0"
        ;;
    "ls")
        echo "v21.5.0"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN/fnm"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run bash "$(pwd)/bin/install/node.bash"
    
    [[ "$output" =~ "The latest Node version (v21.5.0) is already installed" ]]
    [ "$status" -eq 0 ]
}

@test "node.bash installs latest version when not present" {
    # Create mock fnm with older version installed
    local log_file="$TEST_TEMP_DIR/fnm.log"
    cat > "$MOCK_BIN/fnm" << EOF
#!/bin/bash
echo "fnm \$@" >> "$log_file"
case "\$1" in
    "ls-remote")
        echo "v21.5.0"
        ;;
    "ls")
        echo "v20.11.0"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN/fnm"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run bash "$(pwd)/bin/install/node.bash"
    
    [[ "$output" =~ "Installing Node.js v21.5.0" ]]
    [[ "$output" =~ "Finished installing Node v21.5.0" ]]
    [ "$status" -eq 0 ]
    
    # Verify fnm commands were called
    grep -q "fnm install v21.5.0 --corepack-enabled" "$log_file"
}