#!/usr/bin/env bash

# UV installation utilities
# Provides functions for managing UV Python package installer

set -euo pipefail

# Check if UV is installed
uv_installed() {
    command -v uv &>/dev/null
}