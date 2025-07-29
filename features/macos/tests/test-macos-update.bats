#!/usr/bin/env bats

# Test suite for macOS update

# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"
setup() {
    # Save original environment
    export ORIGINAL_PATH="$PATH"
    
    export TEST_DIR="$(mktemp -d)"
    export DOTFILES="$TEST_DIR/dotfiles"
    
    mkdir -p "$DOTFILES/features/macos"
    mkdir -p "$DOTFILES/core/detection"
    mkdir -p "$DOTFILES/core/errors"
    
    # Copy necessary files
    cp "${BATS_TEST_DIRNAME}/../utils.bash" "$DOTFILES/features/macos/"
    cp "${BATS_TEST_DIRNAME}/../update.bash" "$DOTFILES/features/macos/"
    
    # Create mock machine detection
    cat > "$DOTFILES/core/detection/machine.bash" << 'EOF'
#!/usr/bin/env bash
init_machine_detection() {
    export MACHINE="${MACHINE:-test}"
    export IS_WORK="${IS_WORK:-false}"
}
EOF
    
    # Create mock error handling
    cat > "$DOTFILES/core/errors/handling.bash" << 'EOF'
#!/usr/bin/env bash
# Mock error handling
EOF
    
    cd "$TEST_DIR"
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    cd /
    rm -rf "$TEST_DIR"
}

@test "update skips on work machine" {
    # Set work machine
    export IS_WORK="true"
    export MACHINE="work"
    
    run "$DOTFILES/features/macos/update.bash"
    
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Skipping macOS updates on work machine" ]]
}

@test "update proceeds on non-work machine" {
    # Set non-work machine
    export IS_WORK="false"
    export MACHINE="air"
    
    # Mock uname to return Darwin
    function uname() {
        echo "Darwin"
    }
    export -f uname
    
    # Create mock softwareupdate that succeeds
    cat > "$TEST_DIR/softwareupdate" << 'EOF'
#!/bin/bash
echo "Software Update Tool"
echo "Finding available software"
echo "No new software available."
exit 0
EOF
    chmod +x "$TEST_DIR/softwareupdate"
    
    # Create mock sudo that just runs the command
    cat > "$TEST_DIR/sudo" << 'EOF'
#!/bin/bash
# Run the command with all its arguments (the first arg after sudo is the command)
"$@"
EOF
    chmod +x "$TEST_DIR/sudo"
    
    # Use restrictive PATH that excludes system package manager paths
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    run "$DOTFILES/features/macos/update.bash"
    
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Machine type: air" ]]
    [[ "$output" =~ "🎉 macOS update process complete!" ]]
}