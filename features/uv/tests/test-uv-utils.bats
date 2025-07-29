#!/usr/bin/env bats

# Test suite for UV utilities

# Set up test environment
setup() {
    # Source the utilities
    source "${BATS_TEST_DIRNAME}/../utils.bash"
    
    # Create temporary directory for tests
    export TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
}

# Clean up after tests
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: is_uv_installed
@test "is_uv_installed detects uv command" {
    # Create a mock uv command
    cat > uv << 'EOF'
#!/bin/bash
echo "uv 0.1.0"
EOF
    chmod +x uv
    export PATH="$TEST_DIR:$PATH"
    
    is_uv_installed
}

@test "is_uv_installed returns false when uv is not installed" {
    # Ensure uv is not in PATH but keep basic commands
    export PATH="/bin:/usr/bin"
    
    ! is_uv_installed
}

# Test: get_uv_version
@test "get_uv_version returns version when uv is installed" {
    # Create a mock uv command
    cat > uv << 'EOF'
#!/bin/bash
echo "uv 0.1.0"
EOF
    chmod +x uv
    export PATH="$TEST_DIR:$PATH"
    
    local version
    version=$(get_uv_version)
    [[ "$version" == "uv 0.1.0" ]]
}

@test "get_uv_version returns 'not installed' when uv is missing" {
    # Ensure uv is not in PATH but keep basic commands
    export PATH="/bin:/usr/bin"
    
    local version
    version=$(get_uv_version)
    [[ "$version" == "not installed" ]]
}

# Test: install_uv with brew available
@test "install_uv uses homebrew to install" {
    # Create mock brew command that succeeds
    cat > brew << 'EOF'
#!/bin/bash
if [[ "$1" == "install" && "$2" == "uv" ]]; then
    echo "Installing uv..."
    exit 0
fi
echo "Unknown brew command: $*" >&2
exit 1
EOF
    chmod +x brew
    export PATH="$TEST_DIR:$PATH"
    
    install_uv
}

# Test: install_uv without brew
@test "install_uv fails when brew is not available" {
    # Ensure brew is not in PATH but keep basic commands
    export PATH="/bin:/usr/bin"
    
    ! install_uv
}