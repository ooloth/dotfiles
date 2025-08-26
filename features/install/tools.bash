#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  # Find all install.bash files at the root level of each tool directory except @new and @archive
  install_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "install.bash" -print)

  # Execute each install.bash file
  for file in $install_files; do
    printf "🔄 Running %s\n" "$file"
    printf "Careful! Enable actual command only if you're sure.\n"
    # bash "$file"
  done
}

main "$@"
