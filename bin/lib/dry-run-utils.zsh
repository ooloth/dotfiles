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

# Export functions for use in other scripts
# Functions are available when this file is sourced