#!/usr/bin/env bats

# Test suite for GitHub utilities

# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"
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

# Test: convert_github_https_to_ssh
@test "convert_github_https_to_ssh converts HTTPS URLs correctly" {
    local result
    
    # Test standard GitHub HTTPS URL
    result=$(convert_github_https_to_ssh "https://github.com/user/repo.git")
    [[ "$result" == "git@github.com:user/repo.git" ]]
    
    # Test GitHub HTTPS URL without .git
    result=$(convert_github_https_to_ssh "https://github.com/user/repo")
    [[ "$result" == "git@github.com:user/repo" ]]
    
    # Test non-GitHub URL (should not convert)
    result=$(convert_github_https_to_ssh "https://gitlab.com/user/repo")
    [[ "$result" == "https://gitlab.com/user/repo" ]]
    
    # Test already SSH URL (should not change)
    result=$(convert_github_https_to_ssh "git@github.com:user/repo.git")
    [[ "$result" == "git@github.com:user/repo.git" ]]
}

# Test: is_https_url
@test "is_https_url detects HTTPS URLs correctly" {
    is_https_url "https://github.com/user/repo"
    is_https_url "https://example.com"
    ! is_https_url "http://example.com"
    ! is_https_url "git@github.com:user/repo"
    ! is_https_url "ssh://git@github.com/user/repo"
}

# Test: is_github_cli_installed
@test "is_github_cli_installed detects gh command" {
    # Create a mock gh command
    cat > gh << 'EOF'
#!/bin/bash
echo "gh version 2.0.0"
EOF
    chmod +x gh
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    is_github_cli_installed
}

# Test: get_git_remote_url in a git repository
@test "get_git_remote_url returns remote URL" {
    # Initialize a git repo
    git init
    git remote add origin "https://github.com/test/repo.git"
    
    local url
    url=$(get_git_remote_url "origin")
    [[ "$url" == "https://github.com/test/repo.git" ]]
    
    # Test non-existent remote
    url=$(get_git_remote_url "upstream")
    [[ -z "$url" ]]
}

# Test: set_git_remote_url
@test "set_git_remote_url updates remote URL" {
    # Initialize a git repo
    git init
    git remote add origin "https://github.com/test/repo.git"
    
    # Update the URL
    set_git_remote_url "origin" "git@github.com:test/repo.git"
    
    # Verify the change
    local url
    url=$(get_git_remote_url "origin")
    [[ "$url" == "git@github.com:test/repo.git" ]]
}

# Test: display_ssh_public_key
@test "display_ssh_public_key shows key when it exists" {
    # Create a mock SSH directory and key
    mkdir -p "$HOME/.ssh"
    echo "ssh-rsa AAAAB3NzaC1yc2EA... test@example.com" > "$HOME/.ssh/id_rsa.pub"
    
    local output
    output=$(display_ssh_public_key)
    [[ "$output" == "ssh-rsa AAAAB3NzaC1yc2EA... test@example.com" ]]
}

# Test: display_ssh_public_key with missing key
@test "display_ssh_public_key fails when key is missing" {
    # Ensure SSH directory doesn't exist
    rm -rf "$HOME/.ssh"
    
    ! display_ssh_public_key
}