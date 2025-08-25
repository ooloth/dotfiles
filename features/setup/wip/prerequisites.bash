#!/usr/bin/env bash

# Prerequisite validation utilities for dotfiles setup
# Validates system requirements before installation begins

set -euo pipefail

# Minimum supported macOS version (major.minor)
readonly MIN_MACOS_VERSION="12.0"

# Validate Command Line Tools are installed
validate_command_line_tools() {
    local xcode_path
    
    # Check if xcode-select can find the developer directory
    if xcode_path=$(xcode-select -p 2>/dev/null); then
        # Verify the path exists and contains expected tools
        if [[ -d "$xcode_path" && -f "$xcode_path/usr/bin/git" ]]; then
            return 0
        else
            echo "Command Line Tools directory exists but appears incomplete" >&2
            return 1
        fi
    else
        echo "Command Line Tools not found. Install with: xcode-select --install" >&2
        return 1
    fi
}

# Validate network connectivity to essential services
validate_network_connectivity() {
    local hosts=("github.com" "raw.githubusercontent.com")
    local failed_hosts=()
    
    for host in "${hosts[@]}"; do
        # Use ping with timeout to test connectivity
        if ! ping -c 1 -W 3000 "$host" >/dev/null 2>&1; then
            failed_hosts+=("$host")
        fi
    done
    
    if [[ ${#failed_hosts[@]} -gt 0 ]]; then
        echo "Network connectivity failed for: ${failed_hosts[*]}" >&2
        echo "Please check your internet connection and try again" >&2
        return 1
    fi
    
    return 0
}

# Validate directory exists and has proper permissions
validate_directory_permissions() {
    local directory="$1"
    
    if [[ -z "$directory" ]]; then
        echo "Directory path is required" >&2
        return 1
    fi
    
    # Check if directory exists
    if [[ ! -d "$directory" ]]; then
        echo "Directory does not exist: $directory" >&2
        return 1
    fi
    
    return 0
}

# Validate write permissions to a directory
validate_write_permissions() {
    local directory="$1"
    
    if [[ -z "$directory" ]]; then
        echo "Directory path is required" >&2
        return 1
    fi
    
    # Check if directory exists first
    if [[ ! -d "$directory" ]]; then
        echo "Directory does not exist: $directory" >&2
        return 1
    fi
    
    # Test write permissions by creating a temporary file
    local test_file="$directory/.dotfiles_write_test_$$"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        return 0
    else
        echo "No write permission for directory: $directory" >&2
        return 1
    fi
}

# Validate macOS version compatibility
validate_macos_version() {
    local current_version
    local major minor
    local min_major min_minor
    
    # Get current macOS version
    current_version=$(sw_vers -productVersion 2>/dev/null)
    if [[ -z "$current_version" ]]; then
        echo "Unable to determine macOS version" >&2
        return 1
    fi
    
    # Parse current version
    major=$(echo "$current_version" | cut -d. -f1)
    minor=$(echo "$current_version" | cut -d. -f2)
    
    # Parse minimum version
    min_major=$(echo "$MIN_MACOS_VERSION" | cut -d. -f1)
    min_minor=$(echo "$MIN_MACOS_VERSION" | cut -d. -f2)
    
    # Compare versions
    if [[ "$major" -gt "$min_major" ]] || 
       [[ "$major" -eq "$min_major" && "$minor" -ge "$min_minor" ]]; then
        return 0
    else
        echo "Unsupported macOS version: $current_version (minimum: $MIN_MACOS_VERSION)" >&2
        return 1
    fi
}

# Validate essential directories for dotfiles installation
validate_essential_directories() {
    local directories=(
        "$HOME"
        "/usr/local"
        "/opt"
    )
    
    local failed_dirs=()
    
    for dir in "${directories[@]}"; do
        if ! validate_directory_permissions "$dir"; then
            failed_dirs+=("$dir")
        fi
    done
    
    if [[ ${#failed_dirs[@]} -gt 0 ]]; then
        echo "Essential directory validation failed for: ${failed_dirs[*]}" >&2
        return 1
    fi
    
    return 0
}

# Run comprehensive prerequisite validation
run_prerequisite_validation() {
    local validation_functions=(
        "validate_command_line_tools"
        "validate_network_connectivity"
        "validate_macos_version"
        "validate_essential_directories"
    )
    
    local failed_validations=()
    local exit_code=0
    
    echo "Running prerequisite validation checks..."
    
    for validation_func in "${validation_functions[@]}"; do
        echo "  Checking: ${validation_func#validate_}"
        
        if ! "$validation_func"; then
            failed_validations+=("$validation_func")
            exit_code=1
        else
            echo "    ✓ Passed"
        fi
    done
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ All prerequisite validation checks passed"
    else
        echo "❌ Prerequisite validation failed:"
        for failed_func in "${failed_validations[@]}"; do
            echo "  - ${failed_func#validate_}"
        done
    fi
    
    return $exit_code
}