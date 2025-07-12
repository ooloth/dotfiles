#!/usr/bin/env bash
# Utilities for managing file permissions and executable modes

set -euo pipefail

# Check if fd command is available
is_fd_available() {
  command -v fd >/dev/null 2>&1
}

# Check if find command is available
is_find_available() {
  command -v find >/dev/null 2>&1
}

# Check if chmod command is available
is_chmod_available() {
  command -v chmod >/dev/null 2>&1
}

# Make a single file executable
make_file_executable() {
  local file_path="$1"
  
  if [[ ! -f "$file_path" ]]; then
    echo "❌ File does not exist: $file_path"
    return 1
  fi
  
  if ! chmod +x "$file_path"; then
    echo "❌ Failed to make file executable: $file_path"
    return 1
  fi
  
  echo "✅ Made executable: $file_path"
}

# Check if a file is executable
is_file_executable() {
  local file_path="$1"
  [[ -x "$file_path" ]]
}

# Find files by extension using fd (preferred)
find_files_by_extension_fd() {
  local directory="$1"
  local extension="$2"
  
  if ! is_fd_available; then
    echo "❌ fd command not available"
    return 1
  fi
  
  fd . "$directory" -e "$extension" 2>/dev/null
}

# Find files by extension using find (fallback)
find_files_by_extension_find() {
  local directory="$1"
  local extension="$2"
  
  if ! is_find_available; then
    echo "❌ find command not available"
    return 1
  fi
  
  find "$directory" -name "*.${extension}" -type f 2>/dev/null
}

# Find files by extension (auto-select tool)
find_files_by_extension() {
  local directory="$1"
  local extension="$2"
  
  if is_fd_available; then
    find_files_by_extension_fd "$directory" "$extension"
  elif is_find_available; then
    find_files_by_extension_find "$directory" "$extension"
  else
    echo "❌ Neither fd nor find command available"
    return 1
  fi
}

# Make all files with specific extension executable in a directory
make_extension_executable() {
  local directory="$1"
  local extension="$2"
  local dry_run="${3:-false}"
  
  if [[ ! -d "$directory" ]]; then
    echo "❌ Directory does not exist: $directory"
    return 1
  fi
  
  if ! is_chmod_available; then
    echo "❌ chmod command not available"
    return 1
  fi
  
  echo "🔍 Finding .$extension files in $directory"
  
  local files_found=0
  local files_processed=0
  
  # Process files one by one for better error handling
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      files_found=$((files_found + 1))
      
      if [[ "$dry_run" == "true" ]]; then
        if is_file_executable "$file"; then
          echo "[DRY RUN] Already executable: $file"
        else
          echo "[DRY RUN] Would make executable: $file"
        fi
        files_processed=$((files_processed + 1))
      else
        if is_file_executable "$file"; then
          echo "✓ Already executable: $file"
          files_processed=$((files_processed + 1))
        else
          if make_file_executable "$file"; then
            files_processed=$((files_processed + 1))
          fi
        fi
      fi
    fi
  done < <(find_files_by_extension "$directory" "$extension")
  
  echo ""
  echo "📊 Found $files_found .$extension files, processed $files_processed"
  
  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] File permissions would be updated"
  else
    echo "🚀 All .$extension files are executable"
  fi
}

# Make all script files executable in dotfiles bin directory
update_dotfiles_script_permissions() {
  local dotfiles_dir="${1:-$HOME/Repos/ooloth/dotfiles}"
  local dry_run="${2:-false}"
  
  local bin_dir="$dotfiles_dir/bin"
  
  if [[ ! -d "$bin_dir" ]]; then
    echo "❌ Dotfiles bin directory not found: $bin_dir"
    return 1
  fi
  
  echo "🔋 Updating executable permissions for dotfiles scripts"
  echo ""
  
  # Process different script types
  local extensions=("zsh" "bash" "sh")
  local total_processed=0
  
  for ext in "${extensions[@]}"; do
    echo "Processing .$ext files..."
    
    # Count files before processing
    local file_count
    file_count=$(find_files_by_extension "$bin_dir" "$ext" | wc -l)
    
    if [[ "$file_count" -gt 0 ]]; then
      make_extension_executable "$bin_dir" "$ext" "$dry_run"
      total_processed=$((total_processed + file_count))
    else
      echo "No .$ext files found in $bin_dir"
    fi
    echo ""
  done
  
  echo "📋 Summary: Processed $total_processed script files total"
}

# Check permissions for a specific file
check_file_permissions() {
  local file_path="$1"
  
  if [[ ! -e "$file_path" ]]; then
    echo "❌ File does not exist: $file_path"
    return 1
  fi
  
  local permissions
  permissions=$(stat -c '%A' "$file_path" 2>/dev/null || stat -f '%Sp' "$file_path" 2>/dev/null || echo "unknown")
  
  echo "File: $file_path"
  echo "Permissions: $permissions"
  
  if is_file_executable "$file_path"; then
    echo "Status: ✅ Executable"
  else
    echo "Status: ❌ Not executable"
  fi
}

# Validate environment for permission management
validate_permission_environment() {
  if ! is_chmod_available; then
    echo "❌ chmod command not available"
    return 1
  fi
  
  # Check if we have at least one file finding tool
  if ! is_fd_available && ! is_find_available; then
    echo "❌ Neither fd nor find command available"
    return 1
  fi
  
  # Prefer fd but note if using fallback
  if is_fd_available; then
    echo "✅ Using fd for file discovery"
  else
    echo "⚠️  Using find as fallback (fd preferred but not available)"
  fi
}