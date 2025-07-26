#!/usr/bin/env bats

# Test GitHub utility functions
# Tests both utility functions and integration with installation workflow

# Load the GitHub utilities
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

@test "ssh_keys_exist returns 0 when both keys exist and are non-empty" {
    # Create fake home with SSH keys
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key content" > "$fake_home/.ssh/id_rsa"
    echo "fake public key content" > "$fake_home/.ssh/id_rsa.pub"
    
    # Override HOME for this test
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 0 ]
}

@test "ssh_keys_exist returns 1 when private key is missing" {
    # Create fake home with only public key
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake public key content" > "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "ssh_keys_exist returns 1 when public key is missing" {
    # Create fake home with only private key
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    echo "fake private key content" > "$fake_home/.ssh/id_rsa"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "ssh_keys_exist returns 1 when keys are empty" {
    # Create fake home with empty key files
    local fake_home="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$fake_home/.ssh"
    touch "$fake_home/.ssh/id_rsa"
    touch "$fake_home/.ssh/id_rsa.pub"
    
    export HOME="$fake_home"
    
    run ssh_keys_exist
    [ "$status" -eq 1 ]
}

@test "get_git_remote_url returns remote URL for valid git repository" {
    # Create a fake git repository
    local fake_repo="$TEST_TEMP_DIR/fake_repo"
    mkdir -p "$fake_repo"
    cd "$fake_repo"
    git init
    git remote add origin "https://github.com/user/repo.git"
    
    run get_git_remote_url "$fake_repo"
    [ "$status" -eq 0 ]
    [ "$output" = "https://github.com/user/repo.git" ]
}

@test "get_git_remote_url returns 1 for non-existent directory" {
    run get_git_remote_url "/nonexistent/directory"
    [ "$status" -eq 1 ]
}

@test "get_git_remote_url returns 1 for directory without git repository" {
    local non_git_dir="$TEST_TEMP_DIR/not_git"
    mkdir -p "$non_git_dir"
    
    run get_git_remote_url "$non_git_dir"
    [ "$status" -eq 1 ]
}

@test "is_https_remote returns 0 for GitHub HTTPS URLs" {
    run is_https_remote "https://github.com/user/repo.git"
    [ "$status" -eq 0 ]
}

@test "is_https_remote returns 1 for SSH URLs" {
    run is_https_remote "git@github.com:user/repo.git"
    [ "$status" -eq 1 ]
}

@test "is_https_remote returns 1 for non-GitHub HTTPS URLs" {
    run is_https_remote "https://gitlab.com/user/repo.git"
    [ "$status" -eq 1 ]
}

@test "convert_https_to_ssh converts GitHub HTTPS URL to SSH format" {
    run convert_https_to_ssh "https://github.com/user/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "git@github.com:user/repo.git" ]
}

@test "convert_https_to_ssh returns unchanged URL for non-HTTPS URLs" {
    run convert_https_to_ssh "git@github.com:user/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "git@github.com:user/repo.git" ]
}

@test "set_git_remote_url updates remote URL in git repository" {
    # Create a fake git repository
    local fake_repo="$TEST_TEMP_DIR/fake_repo"
    mkdir -p "$fake_repo"
    cd "$fake_repo"
    git init
    git remote add origin "https://github.com/user/repo.git"
    
    # Update the remote URL
    run set_git_remote_url "$fake_repo" "git@github.com:user/repo.git"
    [ "$status" -eq 0 ]
    
    # Verify the URL was updated
    cd "$fake_repo"
    local new_url
    new_url=$(git config --get remote.origin.url)
    [ "$new_url" = "git@github.com:user/repo.git" ]
}

@test "set_git_remote_url returns 1 for non-existent directory" {
    run set_git_remote_url "/nonexistent/directory" "git@github.com:user/repo.git"
    [ "$status" -eq 1 ]
}