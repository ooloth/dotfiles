#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  # Find all install.bash files
  install_files=$(find "${DOTFILES}/tools" -type f -name "install.bash")

  # Iterate over the files and execute them
  for file in $install_files; do
    printf "🔄 Running %s\n" "$file"
    printf "Careful! Enable actual command only if you're sure.\n"
    # bash "$file"
  done
}

main "$@"
