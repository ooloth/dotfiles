#!/usr/bin/env zsh

# Homebrew utility functions for installation scripts
# Provides reusable functionality for detecting and working with Homebrew

# Detect if Homebrew is installed on the system
# Returns: 0 if installed, 1 if not installed
detect_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is installed"
        return 0
    else
        echo "Homebrew is not installed"
        return 1
    fi
}

# TODO: Use in bin/install/homebrew.zsh for conditional installation
# TODO: Use in prerequisite validation for dependency checking