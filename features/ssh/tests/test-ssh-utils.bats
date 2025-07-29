#!/usr/bin/env bats

# Test SSH utility functions
# Tests key detection, generation, config management, and agent operations
# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"

# Load the SSH utilities
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original HOME for restoration
    export ORIGINAL_HOME="$HOME"
}

teardown() {
    # Restore original HOME
    export HOME="$ORIGINAL_HOME"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "get_ssh_key_paths sets correct paths" {
    export HOME="$TEST_TEMP_DIR/fake_home"
    
    get_ssh_key_paths
    
    [ "$SSH_DIR" = "$TEST_TEMP_DIR/fake_home/.ssh" ]
    [ "$SSH_PRIVATE_KEY" = "$TEST_TEMP_DIR/fake_home/.ssh/id_rsa" ]
    [ "$SSH_PUBLIC_KEY" = "$TEST_TEMP_DIR/fake_home/.ssh/id_rsa.pub" ]
}

@test "ssh_keys_exist returns 0 when both keys exist and are non-empty" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key content" > "$fake_home/.ssh/id_rsa"
    echo "fake public key content" > "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 0 ]
}

@test "ssh_keys_exist returns 1 when private key is missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake public key content" > "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "ssh_keys_exist returns 1 when public key is missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key content" > "$fake_home/.ssh/id_rsa"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "ssh_keys_exist returns 1 when keys are empty" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    touch "$fake_home/.ssh/id_rsa"
    touch "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "detect_ssh_keys prints success message when keys exist" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key content" > "$fake_home/.ssh/id_rsa"
    echo "fake public key content" > "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run detect_ssh_keys
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSH key pair found"* ]]
}

@test "detect_ssh_keys prints failure message when keys missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    
    export HOME="$fake_home"
    
    run detect_ssh_keys
    [ "$status" -eq 1 ]
    [[ "$output" == *"No SSH key pair found"* ]]
}

@test "create_ssh_config creates config with correct settings" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local ssh_config="$fake_home/.ssh/config"
    
    export HOME="$fake_home"
    
    run create_ssh_config "$ssh_config"
    [ "$status" -eq 0 ]
    [ -f "$ssh_config" ]
    
    # Verify config contents
    grep -Fxq "Host *" "$ssh_config"
    grep -Fxq "  AddKeysToAgent yes" "$ssh_config"
    grep -Fxq "  UseKeychain yes" "$ssh_config"
    grep -Fxq "  IdentityFile $fake_home/.ssh/id_rsa" "$ssh_config"
}

@test "create_ssh_config creates .ssh directory if missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local ssh_config="$fake_home/.ssh/config"
    
    export HOME="$fake_home"
    
    # Ensure .ssh doesn't exist
    [ ! -d "$fake_home/.ssh" ]
    
    run create_ssh_config "$ssh_config"
    [ "$status" -eq 0 ]
    [ -d "$fake_home/.ssh" ]
}

@test "ssh_config_has_required_settings returns 0 when all settings present" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local ssh_config="$fake_home/.ssh/config"
    
    export HOME="$fake_home"
    
    # Create config with all required settings
    create_ssh_config "$ssh_config"
    
    run ssh_config_has_required_settings "$ssh_config"
    [ "$status" -eq 0 ]
}

@test "ssh_config_has_required_settings returns 1 when file missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local ssh_config="$fake_home/.ssh/config"
    
    export HOME="$fake_home"
    
    run ssh_config_has_required_settings "$ssh_config"
    [ "$status" -eq 1 ]
}

@test "ssh_config_has_required_settings returns 1 when settings incomplete" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local ssh_config="$fake_home/.ssh/config"
    
    export HOME="$fake_home"
    
    # Create config with missing settings
    mkdir -p "$fake_home/.ssh"
    cat > "$ssh_config" << EOF
Host *
  AddKeysToAgent yes
EOF
    
    run ssh_config_has_required_settings "$ssh_config"
    [ "$status" -eq 1 ]
}

@test "generate_ssh_keys creates key pair files" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    
    export HOME="$fake_home"
    
    # Mock ssh-keygen to create fake key files
    ssh-keygen() {
        # Parse arguments to find output file
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "fake private key" > "$output_file"
            echo "fake public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    run generate_ssh_keys
    [ "$status" -eq 0 ]
    [ -f "$fake_home/.ssh/id_rsa" ]
    [ -f "$fake_home/.ssh/id_rsa.pub" ]
}

@test "add_ssh_key_to_agent handles missing ssh-agent gracefully" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key" > "$fake_home/.ssh/id_rsa"
    
    export HOME="$fake_home"
    
    # Mock ssh-add to simulate no agent running initially
    ssh-add() {
        case "$1" in
            -l) return 2 ;;  # No agent running
            --apple-use-keychain|*) return 0 ;;  # Success adding key
        esac
    }
    export -f ssh-add
    
    # Mock ssh-agent
    ssh-agent() {
        echo "SSH_AUTH_SOCK=/tmp/fake.sock; export SSH_AUTH_SOCK;"
        echo "SSH_AGENT_PID=12345; export SSH_AGENT_PID;"
    }
    export -f ssh-agent
    
    run add_ssh_key_to_agent
    [ "$status" -eq 0 ]
}