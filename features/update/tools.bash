#!/usr/bin/env bash
set -euo pipefail

main() {
  priority_files=(
    "${DOTFILES}/features/update/mode.bash"
    "${DOTFILES}/tools/uv/update.bash"
  )

  # Run priority files first
  for file in "${priority_files[@]}"; do
    bash "$file"
  done

  # Find all update.bash files at the root level of each tool directory (except @new and @archive) and sort by parent directory name
  update_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "update.bash" -print | sort -t/ -k5)

  # Filter out priority files from the list
  for priority in "${priority_files[@]}"; do
    update_files=$(echo "$update_files" | grep -v "^$priority$")
  done

  # Execute the remaining update.bash files
  for file in $update_files; do
    bash "$file"
  done
}

# TODO: support updating individual tools?
main "$@"
