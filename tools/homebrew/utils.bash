#!/usr/bin/env bash

# Homebrew utility functions for installation scripts
# Provides reusable functionality for detecting and working with Homebrew

set -euo pipefail

# Detect if Homebrew is installed on the system
# Prints informative messages and returns appropriate exit codes
# Returns: 0 if installed, 1 if not installed
detect_homebrew() {
    # Check if brew command exists and actually works
    if command -v brew >/dev/null 2>&1 && brew --version >/dev/null 2>&1; then
        printf "🍺 Homebrew is already installed\n"
        return 0
    else
        printf "🍺 Homebrew is not installed\n"
        return 1
    fi
}

# Get Homebrew version information
# Returns: 0 if brew is available and version retrieved, 1 otherwise
get_homebrew_version() {
    if command -v brew >/dev/null 2>&1; then
        brew --version 2>/dev/null
        return 0
    else
        echo "Homebrew not available"
        return 1
    fi
}

# Check if Homebrew installation is functional
# Returns: 0 if working properly, 1 if issues detected
validate_homebrew_installation() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew binary not found"
        return 1
    fi
    
    # Test that brew can execute basic commands
    if ! brew --version >/dev/null 2>&1; then
        echo "Homebrew binary found but not functional"
        return 1
    fi
    
    echo "Homebrew installation is functional"
    return 0
}

# Get the appropriate Homebrew prefix based on system architecture
# Returns: /opt/homebrew for Apple Silicon, /usr/local for Intel
get_homebrew_prefix() {
    local arch
    arch=$(uname -m 2>/dev/null || echo "unknown")
    
    case "$arch" in
        "arm64")
            echo "/opt/homebrew"
            ;;
        *)
            # Default to Intel prefix for x86_64 and unknown architectures
            echo "/usr/local"
            ;;
    esac
}

# Ensure Homebrew bin directory is in PATH
# Adds the appropriate Homebrew prefix to PATH if not already present
ensure_homebrew_in_path() {
    local homebrew_prefix
    homebrew_prefix=$(get_homebrew_prefix)
    local homebrew_bin="$homebrew_prefix/bin"
    
    # Check if already in PATH
    if [[ ":$PATH:" != *":$homebrew_bin:"* ]]; then
        export PATH="$homebrew_bin:$PATH"
    fi
}

# Check if a specific Homebrew package is installed
# Args: package_name - name of the package to check
# Returns: 0 if installed, 1 if not installed
is_homebrew_package_installed() {
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        echo "Package name is required" >&2
        return 1
    fi
    
    # Use brew list to check if package is installed
    if brew list --formula 2>/dev/null | grep -q "^${package_name}$"; then
        return 0
    else
        return 1
    fi
}