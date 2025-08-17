#!/usr/bin/env bats

# Test setup.bash main entry point

# Load test helpers
load "../bats-helper.bash"

setup() {
    # Save original environment
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    export ORIGINAL_HOME="${HOME:-}"

    # Create temporary directory for testing
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"

    # Set up test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTFILES="$TEST_TEMP_DIR/home/Repos/ooloth/dotfiles"
    mkdir -p "$HOME"
    mkdir -p "$DOTFILES"
}

teardown() {
    # Restore original environment
    if [[ -n "$ORIGINAL_DOTFILES" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi

    if [[ -n "$ORIGINAL_HOME" ]]; then
        export HOME="$ORIGINAL_HOME"
    else
        unset HOME
    fi

    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "setup.bash exists and is executable" {
    # Check if setup.bash exists in the real dotfiles location
    [ -f "$(pwd)/setup.bash" ]
    [ -x "$(pwd)/setup.bash" ]
}

@test "setup.bash sets DOTFILES environment variable" {
    # Clear DOTFILES to test that setup.bash sets it
    unset DOTFILES

    # Run setup.bash in a way that exports variables
    source "$(pwd)/setup.bash"

    # Check that DOTFILES is set correctly
    [ -n "$DOTFILES" ]
    [[ "$DOTFILES" == "$HOME/Repos/ooloth/dotfiles" ]]
}

@test "setup.bash enables strict error handling" {
    # Create a test script that sources setup.bash and checks error handling
    local test_script="$TEST_TEMP_DIR/test_error.sh"
    cat >"$test_script" <<'EOF'
#!/bin/bash
source "$(pwd)/setup.bash"

# Test that undefined variable causes error
echo "$UNDEFINED_VARIABLE"
EOF

    chmod +x "$test_script"

    # Run the test script - should fail due to undefined variable
    run "$test_script"
    [ "$status" -ne 0 ]
}

@test "setup.bash shows welcome message when run directly" {
    # Run setup.bash with 'n' response to avoid full installation
    run bash -c "echo 'n' | $(pwd)/setup.bash"

    # Check that welcome message is shown
    [[ "$output" =~ "Welcome to your new Mac!" ]]
    [[ "$output" =~ "Sound good?" ]]
    [[ "$output" =~ "No worries! Maybe next time." ]]
    [ "$status" -eq 1 ]
}

@test "setup.bash checks for macOS platform" {
    # Create a mock uname command that returns Linux
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    cat >"$mock_bin/uname" <<'EOF'
#!/bin/bash
echo "Linux"
EOF
    chmod +x "$mock_bin/uname"

    # Run setup.bash with mocked uname
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/setup.bash 2>&1 || true"

    # Check for macOS error message
    [[ "$output" =~ "This script only runs on macOS" ]]
}

@test "setup.bash pulls latest changes when dotfiles already exist" {
    # Create mock git command
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    cat >"$mock_bin/git" <<'EOF'
#!/bin/bash
if [[ "$1" == "pull" ]]; then
    echo "Already up to date."
fi
EOF
    chmod +x "$mock_bin/git"

    # Create the dotfiles directory to simulate it already exists
    mkdir -p "$DOTFILES"

    # Run setup.bash with mocked git, answering 'y' but then it will fail on platform check
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/setup.bash 2>&1 || true"

    # Check that it detected existing dotfiles
    [[ "$output" =~ "Dotfiles are already installed. Pulling latest changes." ]]
}

@test "setup.bash runs bash installation scripts" {
    # Create mock git command
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    cat >"$mock_bin/git" <<'EOF'
#!/bin/bash
if [[ "$1" == "pull" ]]; then
    echo "Already up to date."
fi
EOF
    chmod +x "$mock_bin/git"

    # Create mock installation scripts
    mkdir -p "$DOTFILES/bin/install"

    # Create mock ssh.bash that sets a variable
    cat >"$DOTFILES/bin/install/ssh.bash" <<'EOF'
#!/usr/bin/env bash
echo "Running SSH installation"
export SSH_INSTALL_RAN="true"
EOF
    chmod +x "$DOTFILES/bin/install/ssh.bash"

    # Create mock github.bash
    cat >"$DOTFILES/bin/install/github.bash" <<'EOF'
#!/usr/bin/env bash
echo "Running GitHub installation"
export GITHUB_INSTALL_RAN="true"
EOF
    chmod +x "$DOTFILES/bin/install/github.bash"

    # Create minimal mock utilities to avoid errors
    mkdir -p "$DOTFILES/core/detection"
    mkdir -p "$DOTFILES/core/dry-run"
    mkdir -p "$DOTFILES/core/errors"
    mkdir -p "$DOTFILES/core/prerequisites"
    mkdir -p "$DOTFILES/core/testing"

    echo 'init_machine_detection() { :; }' >"$DOTFILES/core/detection/machine.bash"
    echo 'parse_dry_run_flags() { :; }' >"$DOTFILES/core/dry-run/utils.bash"
    echo '' >"$DOTFILES/core/errors/handling.bash"
    echo 'run_prerequisite_validation() { return 0; }' >"$DOTFILES/core/prerequisites/validation.bash"
    echo 'run_installer() { echo "Installing $1..."; }' >"$DOTFILES/core/testing/bats-helper.bash"

    # Run setup.bash with mocked git
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/setup.bash 2>&1 || true"

    # Check that installation scripts were mentioned/run
    [[ "$output" =~ "Running installations" ]]
}

