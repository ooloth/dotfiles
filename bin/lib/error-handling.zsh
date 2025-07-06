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

# Retry a command with exponential backoff
# TODO: Use for network operations and package installations
retry_with_backoff() {
    local command="$1"
    local max_attempts="${2:-3}"
    local initial_delay="${3:-1}"
    local attempt=1
    local delay=$initial_delay
    
    while [[ $attempt -le $max_attempts ]]; do
        # Try the command
        if eval "$command"; then
            return 0
        fi
        
        # If we've exhausted attempts, fail
        if [[ $attempt -eq $max_attempts ]]; then
            echo "Error: Command failed after $max_attempts attempts" >&2
            echo "Command: $command" >&2
            return 1
        fi
        
        # Wait before retry with exponential backoff
        echo "Attempt $attempt failed, retrying in ${delay}s..." >&2
        sleep $delay
        
        # Increase delay for next attempt
        delay=$((delay * 2))
        ((attempt++))
    done
}

# Export functions for use in other scripts
# Functions are available when this file is sourced