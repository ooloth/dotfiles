#!/usr/bin/env zsh

# Homebrew utility functions for installation scripts
# Provides reusable functionality for detecting and working with Homebrew

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