#!/usr/bin/env bats

# Test suite for Yazi utilities

setup() {
    source "${BATS_TEST_DIRNAME}/../utils.bash"
    export TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    cd "$TEST_DIR"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "get_yazi_flavors_path returns correct path" {
    local expected="$HOME/Repos/yazi-rs/flavors"
    local actual
    actual=$(get_yazi_flavors_path)
    [[ "$actual" == "$expected" ]]
}

@test "get_yazi_config_dir returns correct path" {
    local expected="$HOME/.config/yazi"
    local actual
    actual=$(get_yazi_config_dir)
    [[ "$actual" == "$expected" ]]
}

@test "is_yazi_flavors_installed detects existing installation" {
    # Create flavors directory
    mkdir -p "$HOME/Repos/yazi-rs/flavors"
    
    is_yazi_flavors_installed
}

@test "is_yazi_flavors_installed returns false when not installed" {
    ! is_yazi_flavors_installed
}