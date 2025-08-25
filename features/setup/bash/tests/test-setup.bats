#!/usr/bin/env bats

# Test features/setup/setup.bash main entry point

load "../../../common/testing.bash"

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

@test "features/setup/setup.bash exists and is executable" {
    # Check if features/setup/setup.bash exists in the real dotfiles location
    [ -f "$(pwd)/features/setup/setup.bash" ]
    [ -x "$(pwd)/features/setup/setup.bash" ]
}

@test "features/setup/setup.bash sets DOTFILES environment variable" {
    # Clear DOTFILES to test that features/setup/setup.bash sets it
    unset DOTFILES

    # Run features/setup/setup.bash in a way that exports variables
    source "$(pwd)/features/setup/setup.bash"

    # Check that DOTFILES is set correctly
    [ -n "$DOTFILES" ]
    [[ "$DOTFILES" == "$HOME/Repos/ooloth/dotfiles" ]]
}

@test "features/setup/setup.bash enables strict error handling" {
    # Create a test script that sources features/setup/setup.bash and checks error handling
    local test_script="$TEST_TEMP_DIR/test_error.sh"
    cat >"$test_script" <<'EOF'
#!/bin/bash
source "$(pwd)/features/setup/setup.bash"

# Test that undefined variable causes error
echo "$UNDEFINED_VARIABLE"
EOF

    chmod +x "$test_script"

    # Run the test script - should fail due to undefined variable
    run "$test_script"
    [ "$status" -ne 0 ]
}

@test "features/setup/setup.bash shows welcome message when run directly" {
    # Run features/setup/setup.bash with 'n' response to avoid full installation
    run bash -c "echo 'n' | $(pwd)/features/setup/setup.bash"

    # Check that welcome message is shown
    [[ "$output" =~ "Welcome to your new Mac!" ]]
    [[ "$output" =~ "Sound good?" ]]
    [[ "$output" =~ "No worries! Maybe next time." ]]
    [ "$status" -eq 1 ]
}

@test "features/setup/setup.bash checks for macOS platform" {
    # Create a mock uname command that returns Linux
    local mock_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$mock_bin"
    cat >"$mock_bin/uname" <<'EOF'
#!/bin/bash
echo "Linux"
EOF
    chmod +x "$mock_bin/uname"

    # Run features/setup/setup.bash with mocked uname
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/features/setup/setup.bash 2>&1 || true"

    # Check for macOS error message
    [[ "$output" =~ "This script only runs on macOS" ]]
}

@test "features/setup/setup.bash pulls latest changes when dotfiles already exist" {
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

    # Run features/setup/setup.bash with mocked git, answering 'y' but then it will fail on platform check
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/features/setup/setup.bash 2>&1 || true"

    # Check that it detected existing dotfiles
    [[ "$output" =~ "Dotfiles are already installed. Pulling latest changes." ]]
}

@test "features/setup/setup.bash runs bash installation scripts" {
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

    # Create mock installation script directories
    mkdir -p "$DOTFILES/tools/ssh"
    mkdir -p "$DOTFILES/tools/github"

    # Create mock ssh/install.bash that sets a variable
    cat >"$DOTFILES/tools/ssh/install.bash" <<'EOF'
#!/usr/bin/env bash
echo "Running SSH installation"
export SSH_INSTALL_RAN="true"
EOF
    chmod +x "$DOTFILES/tools/ssh/install.bash"

    # Create mock github/install.bash
    cat >"$DOTFILES/tools/github/install.bash" <<'EOF'
#!/usr/bin/env bash
echo "Running GitHub installation"
export GITHUB_INSTALL_RAN="true"
EOF
    chmod +x "$DOTFILES/tools/github/install.bash"

    # Create minimal mock utilities to avoid errors
    mkdir -p "$DOTFILES/features/common/detection"
    mkdir -p "$DOTFILES/features/common/dry-run"
    mkdir -p "$DOTFILES/features/common/errors"
    mkdir -p "$DOTFILES/features/common/prerequisites"
    mkdir -p "$DOTFILES/features/common/testing"

    echo 'init_machine_detection() { :; }' >"$DOTFILES/features/common/detection/machine.bash"
    echo 'parse_dry_run_flags() { :; }' >"$DOTFILES/features/common/dry-run/utils.bash"
    echo '' >"$DOTFILES/features/common/errors/handling.bash"
    echo 'run_prerequisite_validation() { return 0; }' >"$DOTFILES/features/common/prerequisites/validation.bash"
    echo 'run_installer() { echo "Installing $1..."; }' >"$DOTFILES/features/common/testing.bash"

    # Run features/setup/setup.bash with mocked git
    PATH="$mock_bin:/usr/bin:/bin" run bash -c "echo 'y' | $(pwd)/features/setup/setup.bash 2>&1 || true"

    # Check that installation scripts were mentioned/run
    [[ "$output" =~ "Running installations" ]]
}
