#!/usr/bin/env bash

# Symlink utilities for dotfiles setup
# Provides reusable functionality for managing symbolic links

set -euo pipefail

# Create symlink if it doesn't exist or points to wrong target
# Args: source_file - absolute path to source file
#       target_dir - absolute path to target directory
# Returns: 0 if symlink created/already correct, 1 on error
maybe_symlink() {
    local source_file="${1:-}"
    local target_dir="${2:-}"
    
    if [[ -z "$source_file" ]]; then
        echo "Error: Source file path is required" >&2
        return 1
    fi
    
    if [[ -z "$target_dir" ]]; then
        echo "Error: Target directory path is required" >&2
        return 1
    fi
    
    # Check if source file exists
    if [[ ! -e "$source_file" ]]; then
        echo "Error: Source file does not exist: $source_file" >&2
        return 1
    fi
    
    local file_name
    file_name="$(basename "$source_file")"
    local target_path="$target_dir/$file_name"
    
    # Check if the target file exists and is a symlink pointing to the correct source file
    if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_file" ]]; then
        return 0
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Create or update symlink
    printf "🔗 "  # inline prefix for the output of the next line
    ln -sfv "$source_file" "$target_dir"
}

# Remove broken symlinks from a directory
# Args: directory - path to directory to clean
# Returns: 0 on success, 1 on error
remove_broken_symlinks() {
    local directory="${1:-}"
    
    if [[ -z "$directory" ]]; then
        echo "Error: Directory path is required" >&2
        return 1
    fi
    
    if [[ ! -d "$directory" ]]; then
        echo "Directory does not exist: $directory" >&2
        return 0
    fi
    
    # Find all symlinks in directory and check if they're broken
    local symlink
    while IFS= read -r -d '' symlink; do
        # Check if symlink target exists
        if [[ ! -e "$symlink" ]]; then
            echo "Removing broken symlink: $symlink"
            rm "$symlink"
        fi
    done < <(find "$directory" -maxdepth 1 -type l -print0 2>/dev/null)
    
    return 0
}

# Check if symlink points to correct target
# Args: symlink_path - path to symlink to check
#       expected_target - expected target path
# Returns: 0 if symlink is correct, 1 otherwise
is_symlink_correct() {
    local symlink_path="${1:-}"
    local expected_target="${2:-}"
    
    if [[ -z "$symlink_path" ]] || [[ -z "$expected_target" ]]; then
        return 1
    fi
    
    # Check if it's a symlink and points to correct target
    if [[ -L "$symlink_path" ]] && [[ "$(readlink "$symlink_path")" == "$expected_target" ]]; then
        return 0
    else
        return 1
    fi
}

# Get relative path from one absolute path to another
# Args: from_path - absolute path to start from
#       to_path - absolute path to target
# Returns: relative path on stdout
get_relative_path() {
    local from_path="${1:-}"
    local to_path="${2:-}"
    
    if [[ -z "$from_path" ]] || [[ -z "$to_path" ]]; then
        echo "Error: Both from_path and to_path are required" >&2
        return 1
    fi
    
    # Use Python to calculate relative path (more reliable than shell implementation)
    python3 -c "
import os
import sys
try:
    rel_path = os.path.relpath('$to_path', '$from_path')
    print(rel_path)
except ValueError as e:
    print('Error calculating relative path', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null || {
        # Fallback: return absolute path if relative calculation fails
        echo "$to_path"
    }
}

# Create symlink with relative path
# Args: source_file - absolute path to source file
#       target_dir - absolute path to target directory
# Returns: 0 if symlink created/already correct, 1 on error
maybe_symlink_relative() {
    local source_file="${1:-}"
    local target_dir="${2:-}"
    
    if [[ -z "$source_file" ]] || [[ -z "$target_dir" ]]; then
        echo "Error: Both source file and target directory are required" >&2
        return 1
    fi
    
    # Check if source file exists
    if [[ ! -e "$source_file" ]]; then
        echo "Error: Source file does not exist: $source_file" >&2
        return 1
    fi
    
    local file_name
    file_name="$(basename "$source_file")"
    local target_path="$target_dir/$file_name"
    
    # Calculate relative path from target directory to source file
    local relative_source
    relative_source=$(get_relative_path "$target_dir" "$source_file")
    
    # Check if the target file exists and is a symlink pointing to the correct source file
    if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$relative_source" ]]; then
        return 0
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Create or update symlink with relative path
    printf "🔗 "  # inline prefix for the output of the next line
    ln -sfv "$relative_source" "$target_path"
}