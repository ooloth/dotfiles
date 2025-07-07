#!/usr/bin/env bats

# Integration tests for GitHub installation script
# Tests the complete workflow including error handling and user interactions

# Load the GitHub installation script (for testing main function logic)
load "../../bin/install/github.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "convert_dotfiles_remote_to_ssh handles missing dotfiles directory gracefully" {
    # Set up fake environment
    export DOTFILES="$TEST_TEMP_DIR/nonexistent_dotfiles"
    
    run convert_dotfiles_remote_to_ssh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dotfiles directory not found"* ]]
}

@test "convert_dotfiles_remote_to_ssh handles non-git directory gracefully" {
    # Create fake dotfiles directory (not a git repo)
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    mkdir -p "$DOTFILES"
    
    run convert_dotfiles_remote_to_ssh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Could not get git remote URL"* ]]
}

@test "convert_dotfiles_remote_to_ssh converts HTTPS remote to SSH" {
    # Create fake dotfiles git repository with HTTPS remote
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    mkdir -p "$DOTFILES"
    cd "$DOTFILES"
    git init
    git remote add origin "https://github.com/user/dotfiles.git"
    
    run convert_dotfiles_remote_to_ssh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Converting the dotfiles remote URL from HTTPS to SSH"* ]]
    [[ "$output" == *"Dotfiles remote URL has been updated to use SSH"* ]]
    
    # Verify the remote was actually updated
    local new_url
    new_url=$(git config --get remote.origin.url)
    [ "$new_url" = "git@github.com:user/dotfiles.git" ]
}

@test "convert_dotfiles_remote_to_ssh leaves SSH remote unchanged" {
    # Create fake dotfiles git repository with SSH remote
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    mkdir -p "$DOTFILES"
    cd "$DOTFILES"
    git init
    git remote add origin "git@github.com:user/dotfiles.git"
    
    run convert_dotfiles_remote_to_ssh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dotfiles remote URL already uses SSH"* ]]
    
    # Verify the remote wasn't changed
    local url
    url=$(git config --get remote.origin.url)
    [ "$url" = "git@github.com:user/dotfiles.git" ]
}

@test "script can be loaded without errors" {
    # Simple test to verify the script loads properly
    run bash -c "source bin/install/github.bash && echo 'Script loaded successfully'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Script loaded successfully"* ]]
}

@test "main function detects missing SSH keys" {
    # Create fake environment with no SSH keys
    export HOME="$TEST_TEMP_DIR/fake_home"
    mkdir -p "$HOME/.ssh"
    
    # Mock github_ssh_connection_works to return failure
    github_ssh_connection_works() {
        return 1
    }
    
    run bash -c "source bin/install/github.bash; main"
    [ "$status" -eq 1 ]
    [[ "$output" == *"SSH keys not found"* ]]
}