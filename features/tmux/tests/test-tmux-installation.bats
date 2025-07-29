#!/usr/bin/env bats

# Tests for tmux installation functionality

load "../../../core/testing/bats-helper.bash"

setup() {
    # Create temporary directories for testing
    export TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
    export DOTFILES="$BATS_TEST_DIRNAME/../../.."
    
    # Create tmux config directory structure
    mkdir -p "$HOME/.config/tmux/plugins"
    
    # Create mocks directory for test commands
    mkdir -p "$BATS_TEST_DIRNAME/mocks"
    
    # Mock tmux command
    PATH="$BATS_TEST_DIRNAME/mocks:/usr/bin:/bin"
    
    # Source the utils for testing
    source "$DOTFILES/features/tmux/utils.bash"
}

teardown() {
    # Clean up test environment
    if [[ -n "${TEST_HOME:-}" && -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
    
    # Clean up mocks directory
    if [[ -d "$BATS_TEST_DIRNAME/mocks" ]]; then
        rm -rf "$BATS_TEST_DIRNAME/mocks"
    fi
}

@test "tpm_is_installed returns false when tpm directory doesn't exist" {
    run tpm_is_installed
    assert_failure
}

@test "tpm_is_installed returns false when tpm directory exists but tpm binary is missing" {
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    run tpm_is_installed
    assert_failure
}

@test "tpm_is_installed returns true when tpm is properly installed" {
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    run tpm_is_installed
    assert_success
}

@test "tmux_config_exists returns false when config doesn't exist" {
    run tmux_config_exists
    assert_failure
}

@test "tmux_config_exists returns true when config exists" {
    touch "$HOME/.config/tmux/tmux.conf"
    run tmux_config_exists
    assert_success
}

@test "install_tpm creates tpm directory and clones repository" {
    # Create a mock git command that succeeds
    cat > "$BATS_TEST_DIRNAME/mocks/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    mkdir -p "$3"
    touch "$3/tpm"
    exit 0
fi
exit 1
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/git"
    
    run install_tpm
    assert_success
    assert [ -d "$HOME/.config/tmux/plugins/tpm" ]
    assert [ -f "$HOME/.config/tmux/plugins/tpm/tpm" ]
}

@test "install_tpm skips installation if already installed" {
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    
    run install_tpm
    assert_success
    assert_output --partial "tpm is already installed"
}

@test "install_tmux_plugins fails when tpm is not installed" {
    run install_tmux_plugins
    assert_failure
    assert_output --partial "tpm is not installed"
}

@test "install_tmux_plugins runs when tpm is installed" {
    # Setup tpm
    mkdir -p "$HOME/.config/tmux/plugins/tpm/bin"
    cat > "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    
    run install_tmux_plugins
    assert_success
}

@test "validate_tmux_installation checks for required components" {
    # Create mock tmux command
    cat > "$BATS_TEST_DIRNAME/mocks/tmux" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/tmux"
    
    # Missing tpm and config
    run validate_tmux_installation
    assert_failure
    
    # Add tpm
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    touch "$HOME/.config/tmux/plugins/tmp/tpm"
    run validate_tmux_installation
    assert_failure
    
    # Add config
    touch "$HOME/.config/tmux/tmux.conf"
    mkdir -p "$HOME/.config/tmux/plugins/tpm"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    run validate_tmux_installation
    assert_success
}