#!/usr/bin/env bats

# Test feature discovery functionality in setup.bash
# Verifies that both old and new paths are discovered correctly

# Load test helpers
load "../bats-helper.bash"

setup() {
    # Save current directory
    export ORIGINAL_PWD="$PWD"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"

    # Create test directory structure
    export TEST_DIR="$(mktemp -d)"
    export DOTFILES="$TEST_DIR/dotfiles"

    # Create mock dotfiles structure
    mkdir -p "$DOTFILES/bin/install"
    mkdir -p "${DOTFILES}/tools/ssh"
    mkdir -p "${DOTFILES}/tools/git"

    # Change to install directory (as setup.bash does)
    cd "$DOTFILES/bin/install"
}

teardown() {
    # Restore directory and environment
    cd "$ORIGINAL_PWD" || true
    if [[ -n "$ORIGINAL_DOTFILES" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi

    # Clean up test directory
    rm -rf "$TEST_DIR"
}

# Source the run_installer function from setup.bash
load_run_installer() {
    # Extract just the run_installer function from setup.bash
    sed -n '/^run_installer()/,/^}/p' "$ORIGINAL_PWD/setup.bash" >"$TEST_DIR/run_installer.bash"
    source "$TEST_DIR/run_installer.bash"
}

@test "run_installer: prefers feature location over legacy location" {
    load_run_installer

    # Create both locations
    echo 'echo "FEATURE"' >"${DOTFILES}/tools/ssh/install.bash"
    echo 'echo "LEGACY"' >"ssh.bash"

    # Should use feature location
    output=$(run_installer "ssh" 2>&1)
    [[ "$output" == *"Using feature-based installer"* ]]
    [[ "$output" == *"FEATURE"* ]]
    [[ "$output" != *"LEGACY"* ]]
}

@test "run_installer: falls back to legacy location when feature missing" {
    load_run_installer

    # Create only legacy location
    echo 'echo "LEGACY"' >"github.bash"

    # Should use legacy location
    output=$(run_installer "github" 2>&1)
    [[ "$output" == *"Using legacy installer"* ]]
    [[ "$output" == *"LEGACY"* ]]
}

@test "run_installer: handles missing installer gracefully" {
    load_run_installer

    # Don't create any installer
    output=$(run_installer "missing" 2>&1)
    [[ "$output" == *"No installer found for missing"* ]]
}

@test "run_installer: shows correct paths in output" {
    load_run_installer

    # Create feature location
    echo 'echo "TEST"' >"${DOTFILES}/tools/git/install.bash"

    # Check path is shown
    output=$(run_installer "git" 2>&1)
    [[ "$output" == *"${DOTFILES}/tools/git/install.bash"* ]]
}

@test "SSH uses feature location when available" {
    load_run_installer

    # Verify SSH is in features
    echo 'echo "SSH FEATURE"' >"${DOTFILES}/tools/ssh/install.bash"

    output=$(run_installer "ssh" 2>&1)
    [[ "$output" == *"Using feature-based installer"* ]]
    [[ "$output" == *"SSH FEATURE"* ]]
}

