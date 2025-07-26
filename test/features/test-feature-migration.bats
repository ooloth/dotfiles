#!/usr/bin/env bats

# Test that both old and new SSH locations work during migration
# This ensures backwards compatibility while we transition

setup() {
    # Save current directory
    export ORIGINAL_PWD="$PWD"
    
    # Set DOTFILES for testing
    export DOTFILES="$PWD"
}

teardown() {
    # Restore directory
    cd "$ORIGINAL_PWD" || true
}

@test "SSH files exist in both old and new locations" {
    # Old locations
    [[ -f "bin/install/ssh.bash" ]]
    [[ -f "lib/ssh-utils.bash" ]]
    
    # New locations
    [[ -f "features/ssh/install.bash" ]]
    [[ -f "features/ssh/utils.bash" ]]
}

@test "SSH installation scripts have same content except imports" {
    # Compare the scripts (ignoring the source line and shellcheck directive which differ)
    diff -I "source.*" -I "shellcheck source=" "bin/install/ssh.bash" "features/ssh/install.bash"
}

@test "SSH utils have identical content" {
    # Utils should be exactly the same
    diff "lib/ssh-utils.bash" "features/ssh/utils.bash"
}

@test "Both SSH installation scripts are executable" {
    [[ -x "bin/install/ssh.bash" ]]
    [[ -x "features/ssh/install.bash" ]]
}

@test "Tests exist in new location" {
    [[ -f "features/ssh/tests/test-ssh-utils.bats" ]]
    [[ -f "features/ssh/tests/test-ssh-installation.bats" ]]
}