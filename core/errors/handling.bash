#!/usr/bin/env bash

# Error handling utilities for dotfiles setup
# Provides graceful error handling and recovery mechanisms

set -euo pipefail

# Capture and handle command errors with context
capture_error() {
    local command="${1:-}"
    local context="${2:-Command execution}"
    local exit_code
    local output
    
    if [[ -z "$command" ]]; then
        echo "Error: No command provided to capture_error" >&2
        return 1
    fi
    
    # Execute the command and capture output
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Show the output first (if any)
    if [[ -n "$output" ]]; then
        echo "$output"
    fi
    
    # Check if command failed
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: $context failed (exit code: $exit_code)" >&2
        echo "Command: $command" >&2
        return $exit_code
    fi
    
    return 0
}

# Retry a command with exponential backoff
retry_with_backoff() {
    local command="${1:-}"
    local max_attempts="${2:-3}"
    local initial_delay="${3:-1}"
    local attempt=1
    local delay=$initial_delay
    
    if [[ -z "$command" ]]; then
        echo "Error: No command provided to retry_with_backoff" >&2
        return 1
    fi
    
    while [[ $attempt -le $max_attempts ]]; do
        # Try the command
        if eval "$command" 2>/dev/null; then
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
        sleep "$delay"
        
        # Increase delay for next attempt
        delay=$((delay * 2))
        ((attempt++))
    done
}

# Provide user-friendly error messages with helpful suggestions
handle_error() {
    local command="${1:-}"
    local error_code="${2:-}"
    local error_message="${3:-Unknown error}"
    
    if [[ -z "$command" ]]; then
        echo "Error: No command provided to handle_error" >&2
        return 1
    fi
    
    echo "❌ Error occurred while running: $command" >&2
    echo "   Error: $error_message" >&2
    
    # Provide helpful suggestions based on error type
    case "$error_code" in
        "EACCES"|"EPERM")
            echo "   💡 Suggestion: Try running with sudo or check file permissions" >&2
            ;;
        "ENOENT")
            echo "   💡 Suggestion: Check if the file or directory exists" >&2
            ;;
        "ECONNREFUSED"|"ETIMEDOUT")
            echo "   💡 Suggestion: Check your internet connection or try again later" >&2
            ;;
        "ENOSPC")
            echo "   💡 Suggestion: Free up disk space and try again" >&2
            ;;
        *)
            echo "   💡 Suggestion: Check the command syntax and try again" >&2
            ;;
    esac
    
    return 1
}