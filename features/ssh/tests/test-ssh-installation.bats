#!/usr/bin/env bats

# Integration tests for SSH installation script
# Tests the complete workflow including key generation, config, and agent setup

# Load the SSH installation script (for testing main function logic)
load "../install.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    # Create fake dotfiles structure
    mkdir -p "$DOTFILES/features/ssh"
    cp "features/ssh/utils.bash" "$DOTFILES/features/ssh/"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
        export DOTFILES="$ORIGINAL_DOTFILES"
    else
        unset DOTFILES
    fi
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "main exits early when SSH keys already exist" {
    # Create existing SSH keys
    mkdir -p "$HOME/.ssh"
    echo "existing private key" > "$HOME/.ssh/id_rsa"
    echo "existing public key" > "$HOME/.ssh/id_rsa.pub"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSH key pair found"* ]]
    [[ "$output" != *"Generating a new"* ]]
}

@test "main generates keys when none exist" {
    # Ensure no keys exist
    mkdir -p "$HOME/.ssh"
    
    # Mock ssh-keygen to create fake keys
    ssh-keygen() {
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "generated private key" > "$output_file"
            echo "generated public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    # Mock ssh-add for agent operations
    ssh-add() {
        case "$1" in
            -l) return 0 ;;  # Agent is running
            --apple-use-keychain|*) return 0 ;;  # Success adding key
        esac
    }
    export -f ssh-add
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"No SSH key pair found"* ]]
    [[ "$output" == *"Generating a new 2048-bit RSA"* ]]
    [[ "$output" == *"SSH key pair generated successfully"* ]]
    [ -f "$HOME/.ssh/id_rsa" ]
    [ -f "$HOME/.ssh/id_rsa.pub" ]
}

@test "main creates SSH config when missing" {
    # No existing SSH keys - need to generate them
    mkdir -p "$HOME/.ssh"
    
    # Mock ssh-keygen to create fake keys
    ssh-keygen() {
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "generated private key" > "$output_file"
            echo "generated public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    # Mock ssh-add for agent operations
    ssh-add() {
        return 0
    }
    export -f ssh-add
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSH config file does not exist. Creating"* ]]
    [[ "$output" == *"SSH config file created"* ]]
    [ -f "$HOME/.ssh/config" ]
    
    # Verify config contents
    grep -Fxq "Host *" "$HOME/.ssh/config"
    grep -Fxq "  AddKeysToAgent yes" "$HOME/.ssh/config"
}

@test "main updates incomplete SSH config" {
    # No existing SSH keys - need to generate them
    mkdir -p "$HOME/.ssh"
    
    # Create incomplete config
    cat > "$HOME/.ssh/config" << EOF
Host *
  AddKeysToAgent yes
EOF
    
    # Mock ssh-keygen to create fake keys
    ssh-keygen() {
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "generated private key" > "$output_file"
            echo "generated public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    # Mock ssh-add for agent operations
    ssh-add() {
        return 0
    }
    export -f ssh-add
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSH config file found. Checking contents"* ]]
    [[ "$output" == *"does not contain all the expected settings"* ]]
    [[ "$output" == *"SSH config file updated"* ]]
    
    # Verify config was updated with all settings
    grep -Fxq "  UseKeychain yes" "$HOME/.ssh/config"
    grep -Fxq "  IdentityFile $HOME/.ssh/id_rsa" "$HOME/.ssh/config"
}

@test "main adds keys to ssh-agent" {
    # No existing SSH keys - need to generate them
    mkdir -p "$HOME/.ssh"
    
    # Mock ssh-keygen to create fake keys
    ssh-keygen() {
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "generated private key" > "$output_file"
            echo "generated public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    # Track ssh-add calls
    local agent_calls=0
    ssh-add() {
        case "$1" in
            -l) return 0 ;;  # Agent is running
            --apple-use-keychain|*)
                ((agent_calls++))
                return 0
                ;;
        esac
    }
    export -f ssh-add
    export agent_calls
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Adding SSH key pair to ssh-agent and Keychain"* ]]
    [[ "$output" == *"SSH key added successfully"* ]]
}

@test "main handles key generation failure" {
    # Ensure no keys exist
    mkdir -p "$HOME/.ssh"
    
    # Mock ssh-keygen to fail
    ssh-keygen() {
        return 1
    }
    export -f ssh-keygen
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to generate SSH key pair"* ]]
}

@test "main handles agent add failure" {
    # No existing SSH keys - need to generate them
    mkdir -p "$HOME/.ssh"
    
    # Mock ssh-keygen to create fake keys
    ssh-keygen() {
        local output_file=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                -f) output_file="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        if [[ -n "$output_file" ]]; then
            echo "generated private key" > "$output_file"
            echo "generated public key" > "${output_file}.pub"
        fi
        
        return 0
    }
    export -f ssh-keygen
    
    # Mock ssh-add to fail when adding key
    ssh-add() {
        case "$1" in
            -l) return 0 ;;  # Agent is running
            --apple-use-keychain|*) return 1 ;;  # Fail adding key
        esac
    }
    export -f ssh-add
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to add SSH key to agent"* ]]
}