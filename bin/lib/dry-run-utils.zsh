#!/usr/bin/env zsh

# Dry-run utilities for dotfiles setup
# Provides read-only validation and logging capabilities

# Parse command line arguments for dry-run flags
parse_dry_run_flags() {
    # Default to false
    export DRY_RUN="false"
    
    # Check all arguments for --dry-run flag
    for arg in "$@"; do
        if [[ "$arg" == "--dry-run" ]]; then
            export DRY_RUN="true"
            break
        fi
    done
}

# Log actions in dry-run mode without executing them
dry_run_log() {
    local action="$1"
    
    if [[ -z "$action" ]]; then
        echo "Error: No action provided to dry_run_log" >&2
        return 1
    fi
    
    # Always log the action with DRY RUN prefix
    echo "DRY RUN: $action"
    
    # In dry-run mode, we don't execute the action
    return 0
}

# Export functions for use in other scripts
# Functions are available when this file is sourced