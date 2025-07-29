#!/usr/bin/env bats

# Test suite for Yazi utilities

# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"
setup() {
    export TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    cd "$TEST_DIR"
    
    # Source utilities after setting up environment
    source "${BATS_TEST_DIRNAME}/../utils.bash"
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

@test "install_yazi_flavors creates repository" {
    # Create mock git that creates the flavors directory
    cat > "$TEST_DIR/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    mkdir -p "$3"
    mkdir -p "$3/catppuccin-mocha.yazi"
    echo "Cloned repository"
    exit 0
fi
command git "$@"
EOF
    chmod +x "$TEST_DIR/git"
    export PATH="$TEST_DIR:$PATH"
    
    install_yazi_flavors
    
    [[ -d "$HOME/Repos/yazi-rs/flavors" ]]
    [[ -d "$HOME/Repos/yazi-rs/flavors/catppuccin-mocha.yazi" ]]
}

@test "install_yazi_flavors handles missing theme" {
    # Create mock git that doesn't create the expected theme
    cat > "$TEST_DIR/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    mkdir -p "$3"
    echo "Cloned repository without theme"
    exit 0
fi
command git "$@"
EOF
    chmod +x "$TEST_DIR/git"
    export PATH="$TEST_DIR:$PATH"
    
    ! install_yazi_flavors
    
    # Should cleanup after failure
    [[ ! -d "$HOME/Repos/yazi-rs/flavors" ]]
}

@test "setup_yazi_theme creates correct symlink" {
    # Create mock flavors directory
    mkdir -p "$HOME/Repos/yazi-rs/flavors/catppuccin-mocha.yazi"
    
    setup_yazi_theme
    
    [[ -L "$HOME/.config/yazi/flavors" ]]
    [[ "$(readlink "$HOME/.config/yazi/flavors")" == "$HOME/Repos/yazi-rs/flavors/catppuccin-mocha.yazi" ]]
}

@test "setup_yazi_theme handles missing theme source" {
    # Don't create the theme source
    
    ! setup_yazi_theme
}

@test "check_disk_space returns success when space available" {
    # This test assumes we have more than 1MB available (very safe assumption)
    check_disk_space "$HOME/test-path" "1"
}

@test "setup_yazi_theme creates backup of existing file" {
    # Create mock flavors directory
    mkdir -p "$HOME/Repos/yazi-rs/flavors/catppuccin-mocha.yazi"
    
    # Create existing file (not symlink) at target location
    mkdir -p "$HOME/.config/yazi"
    echo "existing content" > "$HOME/.config/yazi/flavors"
    
    setup_yazi_theme
    
    # Should create backup
    [[ -f "$HOME/.config/yazi/flavors.backup."* ]]
    # And create new symlink
    [[ -L "$HOME/.config/yazi/flavors" ]]
}