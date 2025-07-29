#!/usr/bin/env bats

# Test suite for UV installation

# Set up test environment
setup() {
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export DOTFILES="$TEST_DIR/dotfiles"
    
    # Create directory structure
    mkdir -p "$DOTFILES/features/uv"
    mkdir -p "$DOTFILES/core/errors"
    
    # Copy necessary files
    cp "${BATS_TEST_DIRNAME}/../utils.bash" "$DOTFILES/features/uv/"
    cp "${BATS_TEST_DIRNAME}/../install.bash" "$DOTFILES/features/uv/"
    
    # Create mock error handling
    cat > "$DOTFILES/core/errors/handling.bash" << 'EOF'
#!/usr/bin/env bash
# Mock error handling
EOF
    
    cd "$TEST_DIR"
}

# Clean up after tests
teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    cd /
    rm -rf "$TEST_DIR"
}

# Test: Installation with UV already installed
@test "installation skips UV when already installed" {
    # Create mock uv command
    cat > "$TEST_DIR/uv" << 'EOF'
#!/bin/bash
echo "uv 0.1.0"
EOF
    chmod +x "$TEST_DIR/uv"
    
    # Use restrictive PATH that excludes system package manager paths
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    # Run installation
    run "$DOTFILES/features/uv/install.bash"
    
    # Should succeed and indicate uv is already installed
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "UV is already installed" ]]
}

# Test: Installation when UV is not installed
@test "installation installs UV when not present" {
    # Create mock brew command
    cat > "$TEST_DIR/brew" << 'EOF'
#!/bin/bash
if [[ "$1" == "install" && "$2" == "uv" ]]; then
    # Create mock uv after installation
    cat > "$TEST_DIR/uv" << 'UVEOF'
#!/bin/bash
echo "uv 0.1.0"
UVEOF
    chmod +x "$TEST_DIR/uv"
    echo "Installing uv..."
    exit 0
fi
echo "Unknown brew command: $*" >&2
exit 1
EOF
    chmod +x "$TEST_DIR/brew"
    
    # Use restrictive PATH that excludes system package manager paths
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    # Run installation
    run "$DOTFILES/features/uv/install.bash"
    
    # Should succeed and install UV
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "UV not found, installing" ]]
    [[ "$output" =~ "UV installation verified" ]]
}

# Test: Installation fails without Homebrew
@test "installation fails when Homebrew is not available" {
    # Use restrictive PATH without brew (same pattern as other tests)
    PATH="/usr/bin:/bin"
    
    # Run installation
    run "$DOTFILES/features/uv/install.bash"
    
    # Should fail
    [[ "$status" -ne 0 ]]
    [[ "$output" =~ "Homebrew not found" ]]
}