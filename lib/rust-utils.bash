#!/usr/bin/env bash

# Rust installation utilities
# Provides functions for detecting and installing Rust toolchain

set -euo pipefail

# Check if Rust is already installed
rust_installed() {
    command -v rustup &>/dev/null
}

# Set up Rust environment variables
setup_rust_environment() {
    export CARGO_HOME="$HOME/.config/cargo"
    export RUSTUP_HOME="$HOME/.config/rustup"
}

# Install Rust toolchain using rustup
install_rust_toolchain() {
    echo "🦀 Installing Rust toolchain..."
    
    # Download and run rustup installer
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    
    echo "🚀 Finished installing rustup, rustc and cargo."
}