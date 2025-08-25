#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

main() {
  source "${DOTFILES}/features/update/bash/mode.bash"

  # Find all update.bash files
  update_files=$(find "${DOTFILES}/tools" -type f -name "update.bash")

  # Iterate over the files and execute them
  for file in $update_files; do
    printf "🔄 Running %s\n" "$file"
    bash "$file"
  done
}

# TODO: support updating individual tools?
main "$@"
