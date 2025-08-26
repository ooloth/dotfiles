#!/usr/bin/env bash
set -euo pipefail

main() {
  source "${DOTFILES}/features/update/bash/mode.bash"

  # Find all update.bash files at the root level of each tool directory except @new and @archive
  update_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "update.bash" -print)

  # Execute each update.bash file
  for file in $update_files; do
    bash "$file"
  done
}

# TODO: support updating individual tools?
main "$@"
