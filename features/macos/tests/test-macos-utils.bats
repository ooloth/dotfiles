#!/usr/bin/env bats

# Test suite for macOS utilities

setup() {
    source "${BATS_TEST_DIRNAME}/../utils.bash"
    export TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "is_macos detects macOS correctly" {
    # Mock uname command
    function uname() {
        echo "Darwin"
    }
    export -f uname
    
    is_macos
}

@test "is_macos returns false on non-macOS" {
    # Mock uname command
    function uname() {
        echo "Linux"
    }
    export -f uname
    
    ! is_macos
}

@test "is_softwareupdate_available detects command" {
    # Create mock softwareupdate command
    cat > softwareupdate << 'EOF'
#!/bin/bash
echo "Software Update Tool"
EOF
    chmod +x softwareupdate
    export PATH="$TEST_DIR:$PATH"
    
    is_softwareupdate_available
}

@test "is_softwareupdate_available returns false when missing" {
    export PATH="/bin:/usr/bin"
    
    ! is_softwareupdate_available
}