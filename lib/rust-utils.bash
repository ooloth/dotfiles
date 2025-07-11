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