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