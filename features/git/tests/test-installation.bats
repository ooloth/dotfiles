#!/usr/bin/env bats

# Integration tests for GitHub installation script
# Tests the complete workflow including error handling and user interactions

# Load test helper functions
load "../../../test/lib/test-helper.bash"

# Load the utils we're testing
load "../utils.bash"

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

@test "configure_git_global applies settings from config file" {
    # Create a test config file
    local test_config="$TEST_TEMP_DIR/test.gitconfig"
    cat > "$test_config" <<EOF
[user]
    name = Test User
    email = test@example.com
EOF
    
    run configure_git_global "$test_config"
    [ "$status" -eq 0 ]
    
    # Verify the config was applied
    local include_path
    include_path=$(git config --global --get include.path)
    [ "$include_path" = "$test_config" ]
}

@test "configure_git_global handles missing config file" {
    run configure_git_global "/nonexistent/config"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Config file not found"* ]]
}

@test "configure_git_work applies work-specific settings" {
    # Create a test work config
    local work_config="$TEST_TEMP_DIR/work.gitconfig"
    cat > "$work_config" <<EOF
[user]
    email = work@company.com
EOF
    
    run configure_git_work "$work_config"
    [ "$status" -eq 0 ]
    
    # Verify the includeIf was set
    local include_if
    include_if=$(git config --global --get includeIf."gitdir:~/Repos/recursionpharma/".path)
    [ "$include_if" = "$work_config" ]
}

@test "configure_git_ignore sets global excludesfile" {
    # Create a test ignore file
    local ignore_file="$TEST_TEMP_DIR/test.gitignore"
    echo "*.log" > "$ignore_file"
    
    run configure_git_ignore "$ignore_file"
    [ "$status" -eq 0 ]
    
    # Verify the excludesfile was set
    local excludes
    excludes=$(git config --global --get core.excludesfile)
    [ "$excludes" = "$ignore_file" ]
}

@test "validate_git_configuration checks required settings" {
    # Clear git config for test
    git config --global --unset user.name || true
    git config --global --unset user.email || true
    
    # Should fail with missing config
    run validate_git_configuration
    [ "$status" -eq 1 ]
    [[ "$output" == *"user.name not configured"* ]]
    [[ "$output" == *"user.email not configured"* ]]
    
    # Set required config
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
    
    # Should pass now
    run validate_git_configuration
    [ "$status" -eq 0 ]
}

