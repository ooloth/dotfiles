#!/usr/bin/env zsh

# Error handling utilities for dotfiles setup
# Provides graceful error handling and recovery mechanisms

# TODO: Use in all installation scripts to replace aggressive ERR trap
# TODO: Integrate with dry-run mode for error simulation
# TODO: Add rollback capabilities for failed installations

# Capture and handle command errors with context
capture_error() {
    local command="$1"
    local context="${2:-Command execution}"
    local exit_code
    
    # Execute the command
    eval "$command"
    exit_code=$?
    
    # Check if command failed
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: $context failed (exit code: $exit_code)" >&2
        echo "Command: $command" >&2
        return $exit_code
    fi
    
    return 0
}

# Export functions for use in other scripts
# Functions are available when this file is sourced