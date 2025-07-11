#!/usr/bin/env bats

# Test Node.js utility functions

# Load the Node utilities
load "../../lib/node-utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    
    # Create mock bin directory
    export MOCK_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "fnm_installed returns false when fnm not found" {
    # Ensure fnm is not in PATH
    PATH="$MOCK_BIN"
    
    run fnm_installed
    [ "$status" -eq 1 ]
}

@test "fnm_installed returns true when fnm is found" {
    # Create mock fnm command
    cat > "$MOCK_BIN/fnm" << 'EOF'
#!/bin/bash
echo "fnm 1.35.0"
EOF
    chmod +x "$MOCK_BIN/fnm"
    
    # Add mock bin to PATH
    PATH="$MOCK_BIN:$PATH"
    
    run fnm_installed
    [ "$status" -eq 0 ]
}

@test "get_latest_node_version returns latest version from fnm ls-remote" {
    # Create mock fnm command that returns version list
    cat > "$MOCK_BIN/fnm" << 'EOF'
#!/bin/bash
if [[ "$1" == "ls-remote" ]]; then
    cat << 'VERSIONS'
v18.0.0
v18.19.0
v20.0.0
v20.11.0
v21.5.0
VERSIONS
fi
EOF
    chmod +x "$MOCK_BIN/fnm"
    
    # Add mock bin to PATH
    PATH="$MOCK_BIN:$PATH"
    
    run get_latest_node_version
    [ "$status" -eq 0 ]
    [[ "$output" == "v21.5.0" ]]
}