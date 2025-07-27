#!/usr/bin/env bats

# Test Rust utility functions
# Tests command detection, installation validation, version checking, and environment setup

# Load the Rust utilities
load "../utils.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment variables for restoration
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_CARGO_HOME="${CARGO_HOME:-}"
    export ORIGINAL_RUSTUP_HOME="${RUSTUP_HOME:-}"
    export ORIGINAL_PATH="$PATH"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export CARGO_HOME="$ORIGINAL_CARGO_HOME"
    export RUSTUP_HOME="$ORIGINAL_RUSTUP_HOME"
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "command_exists returns 0 for existing command" {
    run command_exists bash
    [ "$status" -eq 0 ]
}

@test "command_exists returns 1 for non-existing command" {
    run command_exists nonexistent_command_12345
    [ "$status" -eq 1 ]
}

@test "command_exists returns 1 for empty command name" {
    run command_exists ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Command name is required"* ]]
}

@test "validate_rustup_installation returns 1 when rustup not available" {
    # Create fake PATH without rustup
    export PATH="/fake/path"
    
    run validate_rustup_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"rustup binary not found"* ]]
}

@test "validate_rustup_installation returns 0 when rustup is functional" {
    # Mock rustup command
    rustup() {
        case "$1" in
            --version) echo "rustup 1.26.0 (fake version)" ;;
            *) return 0 ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run validate_rustup_installation
    [ "$status" -eq 0 ]
    [[ "$output" == *"rustup installation is functional"* ]]
}

@test "validate_rust_installation returns 1 when rustc not available" {
    # Create fake PATH without rustc
    export PATH="/fake/path"
    
    run validate_rust_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"rustc binary not found"* ]]
}

@test "validate_rust_installation returns 1 when cargo not available" {
    # Mock rustc but not cargo
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\necho "rustc 1.70.0 (fake version)"' > "$fake_bin/rustc"
    chmod +x "$fake_bin/rustc"
    export PATH="$fake_bin:$PATH"
    
    run validate_rust_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"cargo binary not found"* ]]
}

@test "validate_rust_installation returns 0 when both rustc and cargo are functional" {
    # Mock both rustc and cargo
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    echo '#!/bin/bash\necho "rustc 1.70.0 (fake version)"' > "$fake_bin/rustc"
    chmod +x "$fake_bin/rustc"
    
    echo '#!/bin/bash\necho "cargo 1.70.0 (fake version)"' > "$fake_bin/cargo"
    chmod +x "$fake_bin/cargo"
    
    export PATH="$fake_bin:$PATH"
    
    run validate_rust_installation
    [ "$status" -eq 0 ]
    [[ "$output" == *"rustc is functional: rustc 1.70.0 (fake version)"* ]]
    [[ "$output" == *"cargo is functional: cargo 1.70.0 (fake version)"* ]]
}

@test "get_current_rust_version returns version when rustc available" {
    # Mock rustc
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\necho "rustc 1.70.0 (90c541806 2023-05-31)"' > "$fake_bin/rustc"
    chmod +x "$fake_bin/rustc"
    export PATH="$fake_bin:$PATH"
    
    run get_current_rust_version
    [ "$status" -eq 0 ]
    [[ "$output" == *"rustc 1.70.0"* ]]
}

@test "get_current_rust_version returns 1 when rustc not available" {
    export PATH="/fake/path"
    
    run get_current_rust_version
    [ "$status" -eq 1 ]
}

@test "get_rustup_version returns version when rustup available" {
    # Mock rustup
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\necho "rustup 1.26.0 (5af9b9484 2023-04-05)"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run get_rustup_version
    [ "$status" -eq 0 ]
    [[ "$output" == *"rustup 1.26.0"* ]]
}

@test "get_rustup_version returns 1 when rustup not available" {
    export PATH="/fake/path"
    
    run get_rustup_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"rustup not available"* ]]
}

@test "is_rust_installed returns 0 when rustup is functional" {
    # Mock rustup command
    rustup() {
        case "$1" in
            --version) echo "rustup 1.26.0 (fake version)" ;;
            *) return 0 ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run is_rust_installed
    [ "$status" -eq 0 ]
}

@test "is_rust_installed returns 1 when rustup not available" {
    export PATH="/fake/path"
    
    run is_rust_installed
    [ "$status" -eq 1 ]
}

@test "list_rust_toolchains returns toolchain list when rustup available" {
    # Mock rustup toolchain list
    rustup() {
        case "$1" in
            toolchain)
                case "$2" in
                    list) echo "stable-x86_64-apple-darwin (default)\nnightly-x86_64-apple-darwin" ;;
                esac
                ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run list_rust_toolchains
    [ "$status" -eq 0 ]
    [[ "$output" == *"stable-x86_64-apple-darwin"* ]]
}

@test "list_rust_toolchains returns 1 when rustup not available" {
    export PATH="/fake/path"
    
    run list_rust_toolchains
    [ "$status" -eq 1 ]
}

@test "get_default_rust_toolchain returns default when rustup available" {
    # Mock rustup default
    rustup() {
        case "$1" in
            default) echo "stable-x86_64-apple-darwin (default)" ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run get_default_rust_toolchain
    [ "$status" -eq 0 ]
    [[ "$output" == *"stable-x86_64-apple-darwin"* ]]
}

@test "get_default_rust_toolchain returns 1 when rustup not available" {
    export PATH="/fake/path"
    
    run get_default_rust_toolchain
    [ "$status" -eq 1 ]
}

@test "validate_cargo_home returns 1 when cargo home missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    export HOME="$fake_home"
    export CARGO_HOME="$fake_home/.config/cargo"
    
    run validate_cargo_home
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cargo home directory not found"* ]]
}

@test "validate_cargo_home returns 1 when cargo bin directory missing" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local cargo_home="$fake_home/.config/cargo"
    
    export HOME="$fake_home"
    export CARGO_HOME="$cargo_home"
    
    # Create cargo home but not bin directory
    mkdir -p "$cargo_home"
    
    run validate_cargo_home
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cargo bin directory not found"* ]]
}

@test "validate_cargo_home returns 0 when cargo home is properly configured" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    local cargo_home="$fake_home/.config/cargo"
    
    export HOME="$fake_home"
    export CARGO_HOME="$cargo_home"
    
    # Create proper cargo home structure
    mkdir -p "$cargo_home/bin"
    
    run validate_cargo_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"Cargo home is properly configured"* ]]
}

@test "setup_rust_environment sets correct environment variables" {
    local fake_home="$TEST_TEMP_DIR/fake_home"
    export HOME="$fake_home"
    
    run setup_rust_environment
    [ "$status" -eq 0 ]
    
    # Check that function output indicates correct setup
    [[ "$output" == *"CARGO_HOME: $fake_home/.config/cargo"* ]]
    [[ "$output" == *"RUSTUP_HOME: $fake_home/.config/rustup"* ]]
}

@test "install_rust sets up correct environment and runs installer" {
    # Mock curl to simulate rustup installer
    curl() {
        # Check that correct arguments are passed
        local has_proto=false
        local has_tlsv=false
        local has_silent=false
        local has_fail=false
        local has_sh_rustup=false
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --proto) has_proto=true; shift 2 ;;
                --tlsv1.2) has_tlsv=true; shift ;;
                -sSf) has_silent=true; has_fail=true; shift ;;
                *rustup.rs) has_sh_rustup=true; shift ;;
                *) shift ;;
            esac
        done
        
        if [[ "$has_proto" == true && "$has_tlsv" == true && "$has_silent" == true && "$has_fail" == true && "$has_sh_rustup" == true ]]; then
            # Simulate successful rustup installation
            echo "info: downloading installer"
            echo "info: profile set to 'default'"
            echo "info: default host triple is x86_64-apple-darwin"
            echo "Rust is installed now. Great!"
            return 0
        else
            return 1
        fi
    }
    export -f curl
    
    # Mock sh to handle the piped installer
    sh() {
        case "$1" in
            -s) 
                case "$2" in
                    --) 
                        case "$3" in
                            -y) echo "Rust installed successfully"; return 0 ;;
                        esac
                        ;;
                esac
                ;;
        esac
        return 1
    }
    export -f sh
    
    # Mock source command for cargo env
    source() {
        return 0
    }
    export -f source
    
    local fake_home="$TEST_TEMP_DIR/fake_home"
    export HOME="$fake_home"
    
    run install_rust
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Rust via rustup"* ]]
    [[ "$output" == *"Rust installed successfully"* ]]
}

@test "update_rust calls rustup update successfully" {
    # Mock rustup update
    rustup() {
        case "$1" in
            update) 
                echo "info: syncing channel updates for 'stable-x86_64-apple-darwin'"
                echo "info: checking for self-updates"
                echo "stable-x86_64-apple-darwin updated - rustc 1.70.0 (90c541806 2023-05-31)"
                return 0
                ;;
            --version) echo "rustup 1.26.0 (fake version)" ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    export PATH="$fake_bin:$PATH"
    
    run update_rust
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Rust toolchain"* ]]
    [[ "$output" == *"Rust toolchain updated successfully"* ]]
}

@test "update_rust returns 1 when rustup not available" {
    export PATH="/fake/path"
    
    run update_rust
    [ "$status" -eq 1 ]
    [[ "$output" == *"rustup not available for updating"* ]]
}