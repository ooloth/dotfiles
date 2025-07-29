#!/usr/bin/env bats

# Test Rust utility functions

# Load the Rust utilities
load "../../lib/rust-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_CARGO_HOME="${CARGO_HOME:-}"
    export ORIGINAL_RUSTUP_HOME="${RUSTUP_HOME:-}"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    if [[ -n "$ORIGINAL_CARGO_HOME" ]]; then
        export CARGO_HOME="$ORIGINAL_CARGO_HOME"
    else
        unset CARGO_HOME
    fi
    
    if [[ -n "$ORIGINAL_RUSTUP_HOME" ]]; then
        export RUSTUP_HOME="$ORIGINAL_RUSTUP_HOME"
    else
        unset RUSTUP_HOME
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "rust_installed returns false when rustup not found" {
    # Ensure rustup is not in PATH
    PATH="$MOCK_BIN"
    
    run rust_installed
    [ "$status" -eq 1 ]
}

@test "rust_installed returns true when rustup is found" {
    # Create mock rustup command
    cat > "$MOCK_BIN/rustup" << 'EOF'
#!/bin/bash
echo "rustup 1.26.0"
EOF
    chmod +x "$MOCK_BIN/rustup"
    
    # Add mock bin to PATH
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run rust_installed
    [ "$status" -eq 0 ]
}

@test "setup_rust_environment sets CARGO_HOME and RUSTUP_HOME" {
    run setup_rust_environment
    [ "$status" -eq 0 ]
    
    # Source the function and check the variables
    setup_rust_environment
    [[ "$CARGO_HOME" == "$HOME/.config/cargo" ]]
    [[ "$RUSTUP_HOME" == "$HOME/.config/rustup" ]]
}

@test "install_rust_toolchain uses curl to download rustup installer" {
    # Create mock curl command that logs its arguments
    local curl_log="$TEST_TEMP_DIR/curl.log"
    cat > "$MOCK_BIN/curl" << EOF
#!/bin/bash
echo "curl called with: \$@" > "$curl_log"
# Mock the rustup script response
cat << 'SCRIPT_EOF'
#!/bin/sh
echo "Mock rustup installer executed"
SCRIPT_EOF
EOF
    chmod +x "$MOCK_BIN/curl"
    
    # Create mock sh command to capture script execution
    cat > "$MOCK_BIN/sh" << 'EOF'
#!/bin/bash
echo "sh executed"
EOF
    chmod +x "$MOCK_BIN/sh"
    
    # Add mock bin to PATH
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run install_rust_toolchain
    [ "$status" -eq 0 ]
    
    # Check that curl was called with correct arguments
    [[ -f "$curl_log" ]]
    local curl_args=$(cat "$curl_log")
    [[ "$curl_args" =~ "--proto" ]]
    [[ "$curl_args" =~ "https://sh.rustup.rs" ]]
}