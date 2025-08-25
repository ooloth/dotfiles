#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

main() {
  source "${DOTFILES}/features/update/bash/mode.bash"

  info "🧰 Updating tools..."

  # Find all update.bash files at the root level of each tool directory except @new and @archive
  update_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "update.bash" -print)

  # Iterate over the files and execute them
  for file in $update_files; do
    printf "🔄 Running %s\n" "$file"
    bash "$file"
  done
}

# TODO: support updating individual tools?
main "$@"
