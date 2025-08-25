#!/usr/bin/env bash

# Rust utility functions for installation scripts
# Provides reusable functionality for working with Rust via rustup

set -euo pipefail

# Check if a command exists
# Args: command_name - name of the command to check
# Returns: 0 if exists, 1 if not found
command_exists() {
    local command_name="$1"
    
    if [[ -z "$command_name" ]]; then
        echo "Command name is required" >&2
        return 1
    fi
    
    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Validate that rustup is properly installed and functional
# Returns: 0 if working properly, 1 if issues detected
validate_rustup_installation() {
    if ! command_exists rustup; then
        echo "rustup binary not found"
        return 1
    fi
    
    # Test that rustup can execute basic commands
    if ! rustup --version >/dev/null 2>&1; then
        echo "rustup binary found but not functional"
        return 1
    fi
    
    echo "rustup installation is functional"
    return 0
}

# Validate that Rust toolchain is properly installed and functional
# Returns: 0 if working properly, 1 if issues detected
validate_rust_installation() {
    # Check rustc
    if ! command_exists rustc; then
        echo "rustc binary not found"
        return 1
    fi
    
    # Check cargo
    if ! command_exists cargo; then
        echo "cargo binary not found"
        return 1
    fi
    
    # Test that rustc can execute and show version
    local rustc_version
    if rustc_version=$(rustc --version 2>/dev/null); then
        echo "rustc is functional: $rustc_version"
    else
        echo "rustc binary found but not functional"
        return 1
    fi
    
    # Test that cargo can execute and show version
    local cargo_version
    if cargo_version=$(cargo --version 2>/dev/null); then
        echo "cargo is functional: $cargo_version"
    else
        echo "cargo binary found but not functional"
        return 1
    fi
    
    return 0
}

# Get the currently active Rust version
# Returns: version string on success, 1 on failure
get_current_rust_version() {
    if command_exists rustc; then
        if rustc --version 2>/dev/null; then
            return 0
        fi
    fi
    
    echo "No active Rust version" >&2
    return 1
}

# Get rustup version information
# Returns: 0 if rustup is available and version retrieved, 1 otherwise
get_rustup_version() {
    if command_exists rustup; then
        rustup --version 2>/dev/null
        return 0
    else
        echo "rustup not available"
        return 1
    fi
}

# Check if Rust is already installed (rustup exists and is functional)
# Returns: 0 if installed, 1 if not installed
is_rust_installed() {
    if command_exists rustup && validate_rustup_installation >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install Rust using rustup with custom paths
# Returns: 0 on success, 1 on failure
install_rust() {
    echo "Installing Rust via rustup..."
    
    # Set custom paths for cargo and rustup
    export CARGO_HOME="$HOME/.config/cargo"
    export RUSTUP_HOME="$HOME/.config/rustup"
    
    # Download and install rustup
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo "✅ Rust installed successfully"
        
        # Source the cargo environment to make tools available
        # shellcheck source=/dev/null
        source "$CARGO_HOME/env" 2>/dev/null || true
        
        return 0
    else
        echo "❌ Failed to install Rust"
        return 1
    fi
}

# Update Rust toolchain using rustup
# Returns: 0 on success, 1 on failure
update_rust() {
    if ! command_exists rustup; then
        echo "rustup not available for updating"
        return 1
    fi
    
    echo "Updating Rust toolchain..."
    if rustup update 2>/dev/null; then
        echo "✅ Rust toolchain updated successfully"
        return 0
    else
        echo "❌ Failed to update Rust toolchain"
        return 1
    fi
}

# Get list of installed Rust toolchains
# Returns: 0 on success, 1 on failure
list_rust_toolchains() {
    if ! command_exists rustup; then
        echo "rustup not available" >&2
        return 1
    fi
    
    if rustup toolchain list 2>/dev/null; then
        return 0
    else
        echo "Failed to list Rust toolchains" >&2
        return 1
    fi
}

# Get the default Rust toolchain
# Returns: default toolchain string on success, 1 on failure
get_default_rust_toolchain() {
    if ! command_exists rustup; then
        echo "rustup not available" >&2
        return 1
    fi
    
    if rustup default 2>/dev/null; then
        return 0
    else
        echo "Failed to get default Rust toolchain" >&2
        return 1
    fi
}

# Check if cargo home directory exists and is properly configured
# Returns: 0 if properly configured, 1 if issues detected
validate_cargo_home() {
    local cargo_home="${CARGO_HOME:-$HOME/.config/cargo}"
    
    if [[ ! -d "$cargo_home" ]]; then
        echo "Cargo home directory not found: $cargo_home"
        return 1
    fi
    
    if [[ ! -d "$cargo_home/bin" ]]; then
        echo "Cargo bin directory not found: $cargo_home/bin"
        return 1
    fi
    
    echo "Cargo home is properly configured: $cargo_home"
    return 0
}

# Set up Rust environment variables
# This function sets the custom paths for CARGO_HOME and RUSTUP_HOME
setup_rust_environment() {
    export CARGO_HOME="$HOME/.config/cargo"
    export RUSTUP_HOME="$HOME/.config/rustup"
    
    # Add cargo bin to PATH if not already present
    if [[ ":$PATH:" != *":$CARGO_HOME/bin:"* ]]; then
        export PATH="$CARGO_HOME/bin:$PATH"
    fi
    
    echo "Rust environment configured:"
    echo "  CARGO_HOME: $CARGO_HOME"
    echo "  RUSTUP_HOME: $RUSTUP_HOME"
    echo "  PATH includes: $CARGO_HOME/bin"
}