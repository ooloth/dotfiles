#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  local tool="${1:-}"

  # If a specific tool is provided as an argument, install only that tool
  if [[ ! -z "$tool" ]]; then
    bash "${DOTFILES}/tools/${tool}/install.bash"
    return 0
  fi

  # Otherwise, update all tools with an install.bash script
  priority_files=(
    # TODO: populate with files that need to run first
  )

  # Run priority files first
  for file in "${priority_files[@]}"; do
    bash "$file"
  done

  # Find all install.bash files at the root level of each tool directory (except @new and @archive) and sort by parent directory name
  install_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "install.bash" -print | sort -t/ -k5)

  # Filter out priority files from the list
  for priority in "${priority_files[@]}"; do
    install_files=$(echo "$install_files" | grep -v "^$priority$")
  done

  # Execute each install.bash file
  for file in $install_files; do
    printf "🔄 Running %s\n" "$file"
    printf "Careful! Enable actual command only if you're sure.\n"
    # bash "$file"
  done
}

# TODO: support installing individual tools?
main "$@"
