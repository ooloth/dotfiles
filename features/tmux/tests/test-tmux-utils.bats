#!/usr/bin/env bats

# Tests for tmux utility functions

load "../../../core/testing/bats-helper.bash"

setup() {
    # Create temporary directories for testing
    export TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
    export DOTFILES="$BATS_TEST_DIRNAME/../../.."
    
    # Create tmux config directory structure
    mkdir -p "$HOME/.config/tmux/plugins"
    
    # Mock commands
    PATH="$BATS_TEST_DIRNAME/mocks:/usr/bin:/bin"
    
    # Source the utils for testing
    source "$DOTFILES/features/tmux/utils.bash"
}

teardown() {
    # Clean up test environment
    if [[ -n "${TEST_HOME:-}" && -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

# Create mock directory for commands
setup_file() {
    mkdir -p "$BATS_TEST_DIRNAME/mocks"
}

teardown_file() {
    rm -rf "$BATS_TEST_DIRNAME/mocks"
}

@test "tmux_is_running returns false when tmux is not running" {
    # Create mock pgrep that returns false
    cat > "$BATS_TEST_DIRNAME/mocks/pgrep" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/pgrep"
    
    run tmux_is_running
    assert_failure
}

@test "tmux_is_running returns true when tmux is running" {
    # Create mock pgrep that returns true
    cat > "$BATS_TEST_DIRNAME/mocks/pgrep" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/pgrep"
    
    run tmux_is_running
    assert_success
}

@test "reload_tmux_config fails when config doesn't exist" {
    run reload_tmux_config
    assert_failure
    assert_output --partial "Tmux config file not found"
}

@test "reload_tmux_config fails when tmux is not running" {
    touch "$HOME/.config/tmux/tmux.conf"
    
    # Mock pgrep to return false (tmux not running)
    cat > "$BATS_TEST_DIRNAME/mocks/pgrep" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/pgrep"
    
    run reload_tmux_config
    assert_failure
    assert_output --partial "Tmux is not running"
}

@test "reload_tmux_config succeeds when tmux is running and config exists" {
    touch "$HOME/.config/tmux/tmux.conf"
    
    # Mock pgrep to return true (tmux running)
    cat > "$BATS_TEST_DIRNAME/mocks/pgrep" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/pgrep"
    
    # Mock tmux source command
    cat > "$BATS_TEST_DIRNAME/mocks/tmux" << 'EOF'
#!/bin/bash
if [[ "$1" == "source" ]]; then
    exit 0
fi
exit 1
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/tmux"
    
    run reload_tmux_config
    assert_success
}

@test "update_tmux_plugins fails when tpm is not installed" {
    run update_tmux_plugins
    assert_failure
    assert_output --partial "tpm is not installed"
}

@test "update_tmux_plugins runs when tpm is installed" {
    # Setup tpm with update script
    mkdir -p "$HOME/.config/tmux/plugins/tpm/bin"
    cat > "$HOME/.config/tmux/plugins/tpm/bin/update_plugins" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    
    run update_tmux_plugins
    assert_success
}

@test "cleanup_tmux_plugins fails when tpm is not installed" {
    run cleanup_tmux_plugins
    assert_failure
    assert_output --partial "tpm is not installed"
}

@test "cleanup_tmux_plugins runs when tpm is installed" {
    # Setup tpm with clean script
    mkdir -p "$HOME/.config/tmux/plugins/tpm/bin"
    cat > "$HOME/.config/tmux/plugins/tpm/bin/clean_plugins" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$HOME/.config/tmux/plugins/tpm/bin/clean_plugins"
    touch "$HOME/.config/tmux/plugins/tpm/tpm"
    
    run cleanup_tmux_plugins
    assert_success
}