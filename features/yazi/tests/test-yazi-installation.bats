#!/usr/bin/env bats

# Test suite for Yazi installation

setup() {
    export TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR/home"
    export DOTFILES="$TEST_DIR/dotfiles"
    
    mkdir -p "$HOME"
    mkdir -p "$DOTFILES/features/yazi"
    mkdir -p "$DOTFILES/core/detection"
    mkdir -p "$DOTFILES/core/errors"
    
    # Copy necessary files
    cp "${BATS_TEST_DIRNAME}/../utils.bash" "$DOTFILES/features/yazi/"
    cp "${BATS_TEST_DIRNAME}/../install.bash" "$DOTFILES/features/yazi/"
    
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
    cd /
    rm -rf "$TEST_DIR"
}

@test "installation skips on work machine" {
    # Set work machine
    export IS_WORK="true"
    export MACHINE="work"
    
    run "$DOTFILES/features/yazi/install.bash"
    
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Skipping yazi flavors installation on work machine" ]]
}

@test "installation proceeds on non-work machine" {
    # Set non-work machine
    export IS_WORK="false"
    export MACHINE="air"
    
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
    
    run "$DOTFILES/features/yazi/install.bash"
    
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Machine type: air" ]]
    [[ "$output" =~ "Yazi setup complete" ]]
}