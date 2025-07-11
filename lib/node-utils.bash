#!/usr/bin/env bash

# Node.js installation utilities
# Provides functions for managing Node.js via fnm

set -euo pipefail

# Check if fnm is installed
fnm_installed() {
    command -v fnm &>/dev/null
}