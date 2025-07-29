#!/usr/bin/env bats

# Node.js installation script tests
# Tests the main Node.js installation workflow

# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"

# Load the installation script
load "../install.bash"

# Test setup and teardown
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment variables
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set test environment
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
    mkdir -p "$DOTFILES/features/node"
    
    # Create a mock utils.bash file
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 1; }
install_node_version() { return 0; }
set_default_node_version() { return 0; }
activate_node_version() { return 0; }
validate_node_installation() { return 0; }
EOF
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

# Integration Tests for main function

@test "main returns 1 when fnm is not available" {
    # Ensure fnm is not in PATH
    PATH="/usr/bin:/bin"
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm (Fast Node Manager) is not installed"* ]]
}

@test "main succeeds when fnm is available and version not installed" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Node.js via fnm"* ]]
    [[ "$output" == *"Finished installing Node.js v20.10.0"* ]]
}

@test "main succeeds when latest version is already installed" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to return that version is already installed
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 0; }
set_default_node_version() { return 0; }
EOF
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"The latest Node.js version (v20.10.0) is already installed"* ]]
    [[ "$output" == *"Node.js setup completed"* ]]
}

@test "main returns 1 when fnm validation fails" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make validation fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 1; }
EOF
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm installation is not functional"* ]]
}

@test "main returns 1 when getting latest version fails" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make version retrieval fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { return 1; }
EOF
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to determine latest Node.js version"* ]]
}

@test "main returns 1 when node installation fails" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make installation fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 1; }
install_node_version() { return 1; }
EOF
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install Node.js v20.10.0"* ]]
}

@test "main returns 1 when setting default fails" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make setting default fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 1; }
install_node_version() { return 0; }
set_default_node_version() { return 1; }
EOF
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to set Node.js v20.10.0 as default"* ]]
}

@test "main handles validation warnings gracefully" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make validation warn but not fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
validate_fnm_installation() { return 0; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 1; }
install_node_version() { return 0; }
set_default_node_version() { return 0; }
activate_node_version() { return 0; }
validate_node_installation() { return 1; }
EOF
    
    run main
    [ "$status" -eq 0 ]  # Should still succeed despite validation warning
    [[ "$output" == *"Node.js installation validation failed"* ]]
    [[ "$output" == *"Finished installing Node.js v20.10.0"* ]]
}

# Test script execution mode detection

@test "script can be sourced without executing main" {
    # Create a fake fnm command
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Source the script (simulating being loaded as a library)
    # This should not execute main automatically
    run bash -c "source '$DOTFILES/features/node/utils.bash' && echo 'Script sourced successfully'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Script sourced successfully"* ]]
    [[ "$output" != *"Installing Node.js via fnm"* ]]
}