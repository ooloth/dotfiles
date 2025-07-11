#!/usr/bin/env bash

# UV installation utilities
# Provides functions for managing UV Python package installer

set -euo pipefail

# Check if UV is installed
uv_installed() {
    command -v uv &>/dev/null
}

# Install UV via Homebrew
install_uv_via_brew() {
    brew install uv
}

# Get UV version
get_uv_version() {
    uv --version
}