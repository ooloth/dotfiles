#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  local tool="${1:-}"
  local file_name="install.bash"

  # If a specific tool is provided as an argument, install only that tool
  if [[ ! -z "$tool" ]]; then
    if [[ ! -f "${DOTFILES}/tools/${tool}/${file_name}" ]]; then
      echo "❌ No ${file_name} script found for tool: ${tool}"
      return 1
    fi

    bash "${DOTFILES}/tools/${tool}/${file_name}"
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
  install_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "${file_name}" -print | sort -t/ -k5)

  # Filter out priority files from the list
  for file in "${priority_files[@]}"; do
    install_files=$(echo "$install_files" | grep -v "^$file$")
  done

  # Execute each install.bash file
  for file in $install_files; do
    printf "\n🔄 Running %s\n" "$file"
    printf "\n⚠️ Careful! Enable actual command only if you're sure.\n"
    # bash "$file"
  done
}

main "$@"
