#!/usr/bin/env bats

# Test suite for GitHub installation

# Set up test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR/home"
    export DOTFILES="$TEST_DIR/dotfiles"
    
    # Create directory structure
    mkdir -p "$HOME/.ssh"
    mkdir -p "$DOTFILES/features/github"
    mkdir -p "$DOTFILES/core/errors"
    
    # Copy necessary files
    cp "${BATS_TEST_DIRNAME}/../utils.bash" "$DOTFILES/features/github/"
    cp "${BATS_TEST_DIRNAME}/../install.bash" "$DOTFILES/features/github/"
    
    # Create mock error handling
    cat > "$DOTFILES/core/errors/handling.bash" << 'EOF'
#!/usr/bin/env bash
# Mock error handling
EOF
    
    # Create mock SSH key
    echo "ssh-rsa AAAAB3NzaC1yc2EA... test@example.com" > "$HOME/.ssh/id_rsa.pub"
    
    cd "$TEST_DIR"
}

# Clean up after tests
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: Installation with GitHub CLI already installed
@test "installation skips GitHub CLI when already installed" {
    # Create mock gh command
    cat > "$TEST_DIR/gh" << 'EOF'
#!/bin/bash
echo "gh version 2.0.0"
EOF
    chmod +x "$TEST_DIR/gh"
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    # Mock SSH connection success
    function ssh() {
        [[ "$1" == "-T" && "$2" == "git@github.com" ]] && return 1
        command ssh "$@"
    }
    export -f ssh
    
    # Run installation
    run "$DOTFILES/features/github/install.bash"
    
    # Should succeed and indicate gh is already installed
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "GitHub CLI is already installed" ]]
    [[ "$output" =~ "You can already connect to GitHub via SSH" ]]
}

# Test: Installation handles missing SSH key
@test "installation fails gracefully when SSH key is missing" {
    # Remove SSH key
    rm -f "$HOME/.ssh/id_rsa.pub"
    
    # Create mock gh command
    cat > "$TEST_DIR/gh" << 'EOF'
#!/bin/bash
echo "gh version 2.0.0"
EOF
    chmod +x "$TEST_DIR/gh"
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    # Mock SSH connection failure
    function ssh() {
        [[ "$1" == "-T" && "$2" == "git@github.com" ]] && return 255
        command ssh "$@"
    }
    export -f ssh
    
    # Run installation
    run "$DOTFILES/features/github/install.bash"
    
    # Should fail with appropriate message
    [[ "$status" -ne 0 ]]
    [[ "$output" =~ "SSH key not found" ]]
}

# Test: Remote URL conversion
@test "installation converts HTTPS remote to SSH" {
    # Create mock gh command
    cat > "$TEST_DIR/gh" << 'EOF'
#!/bin/bash
echo "gh version 2.0.0"
EOF
    chmod +x "$TEST_DIR/gh"
    PATH="$TEST_DIR:/usr/bin:/bin"
    
    # Mock SSH connection success
    function ssh() {
        [[ "$1" == "-T" && "$2" == "git@github.com" ]] && return 1
        command ssh "$@"
    }
    export -f ssh
    
    # Initialize git repo in dotfiles
    cd "$DOTFILES"
    git init
    git remote add origin "https://github.com/user/dotfiles.git"
    
    # Run installation
    run "$DOTFILES/features/github/install.bash"
    
    # Check that remote was converted
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Converting remote URL from HTTPS to SSH" ]]
    
    # Verify the remote URL was changed
    local new_url
    new_url=$(git config --get remote.origin.url)
    [[ "$new_url" == "git@github.com:user/dotfiles.git" ]]
}