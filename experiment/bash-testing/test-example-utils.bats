#!/usr/bin/env bats

# Load the functions we want to test
load "example-utils.bash"

setup() {
    # Create a temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "command_exists returns 0 for existing commands" {
    run command_exists "ls"
    [ "$status" -eq 0 ]
}

@test "command_exists returns 1 for non-existing commands" {
    run command_exists "nonexistent-command-12345"
    [ "$status" -eq 1 ]
}

@test "detect_ssh_keys finds existing SSH keys" {
    # Mock SSH directory with keys
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key" > "$fake_home/.ssh/id_rsa"
    echo "fake public key" > "$fake_home/.ssh/id_rsa.pub"
    
    # Override HOME for this test
    export HOME="$fake_home"
    
    run detect_ssh_keys
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSH key pair found"* ]]
}

@test "detect_ssh_keys reports missing SSH keys" {
    # Use empty fake home directory
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home"
    
    # Override HOME for this test
    export HOME="$fake_home"
    
    run detect_ssh_keys
    [ "$status" -eq 1 ]
    [[ "$output" == *"No SSH key pair found"* ]]
}

@test "validate_homebrew works when brew is available" {
    # This test will pass/fail based on actual system state
    # In a real scenario, we'd mock the command
    if command -v brew >/dev/null 2>&1; then
        run validate_homebrew
        [ "$status" -eq 0 ]
        [[ "$output" == *"Homebrew found"* ]]
    else
        skip "Homebrew not installed on this system"
    fi
}