#!/usr/bin/env bats

# Test UV utility functions

# Load the UV utilities
load "../../lib/uv-utils.bash"

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

@test "uv_installed returns false when uv not found" {
    # Ensure uv is not in PATH
    PATH="$MOCK_BIN"
    
    run uv_installed
    [ "$status" -eq 1 ]
}

@test "uv_installed returns true when uv is found" {
    # Create mock uv command
    cat > "$MOCK_BIN/uv" << 'EOF'
#!/bin/bash
echo "uv 0.1.35"
EOF
    chmod +x "$MOCK_BIN/uv"
    
    # Add mock bin to PATH
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run uv_installed
    [ "$status" -eq 0 ]
}

@test "install_uv_via_brew installs uv using brew" {
    # Create mock brew command
    local log_file="$TEST_TEMP_DIR/brew.log"
    cat > "$MOCK_BIN/brew" << EOF
#!/bin/bash
echo "brew \$@" > "$log_file"
if [[ "\$1" == "install" && "\$2" == "uv" ]]; then
    echo "Installing uv..."
    echo "uv 0.1.35 installed successfully"
fi
EOF
    chmod +x "$MOCK_BIN/brew"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run install_uv_via_brew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installing uv" ]]
    
    # Check brew was called correctly
    [[ -f "$log_file" ]]
    grep -q "brew install uv" "$log_file"
}

@test "get_uv_version returns version string" {
    # Create mock uv command
    cat > "$MOCK_BIN/uv" << 'EOF'
#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "uv 0.1.35 (f92c209ef 2024-04-11)"
fi
EOF
    chmod +x "$MOCK_BIN/uv"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run get_uv_version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "uv 0.1.35" ]]
}