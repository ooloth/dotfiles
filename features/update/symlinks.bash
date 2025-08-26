#!/usr/bin/env bash
set -euo pipefail

##############
# SYMLINKING #
##############

symlink() {
  # Both arguments should be absolute paths
  local source_file="$1"
  local target_dir="$2"

  # TODO: start by removing broken symlinks in each target directory?
  local file_name
  file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    printf "✅ $file_name symlinked to $target_dir\n"
    return 0
  fi

  mkdir -p "$target_dir"
  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir"
}

#######################
# REMOVE BROKEN LINKS #
#######################
