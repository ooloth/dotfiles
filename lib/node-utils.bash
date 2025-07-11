#!/usr/bin/env bash

# Node.js installation utilities
# Provides functions for managing Node.js via fnm

set -euo pipefail

# Check if fnm is installed
fnm_installed() {
    command -v fnm &>/dev/null
}

# Get latest Node.js version from fnm
get_latest_node_version() {
    fnm ls-remote | tail -n 1
}

# Check if a specific Node version is installed
check_node_version_installed() {
    local version="$1"
    fnm ls | grep -q "$version"
}

# Install Node.js version and set as default
install_node_version() {
    local version="$1"
    echo "🦀 Installing Node.js $version..."
    
    fnm install "$version" --corepack-enabled
    fnm default "$version"
    fnm use "$version"
    
    echo "🚀 Finished installing Node $version."
}