#!/usr/bin/env bash
# Intentionally omitting -e: a failing tool update must not block subsequent tools
set -uo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"
set +e  # utils.bash re-enables -e; disable it to preserve non-blocking behaviour

main() {
  local tool="${1:-}"
  local file_name="update.bash"
  local failed_scripts=()

  # If a specific tool is provided as an argument, update only that tool
  if [[ ! -z "$tool" ]]; then
    if [[ ! -f "${DOTFILES}/tools/${tool}/${file_name}" ]]; then
      echo "❌ No ${file_name} script found for tool: ${tool}"
      return 1
    fi

    bash "${DOTFILES}/tools/${tool}/${file_name}"
    return 0
  fi

  # Otherwise, update all tools with an update.bash script
  priority_files=(
    "${DOTFILES}/features/update/mode.bash"
    "${DOTFILES}/features/update/symlinks.bash"
    "${DOTFILES}/tools/uv/${file_name}"
    "${DOTFILES}/tools/node/${file_name}"
    "${DOTFILES}/tools/homebrew/${file_name}"
  )

  # Run priority files first, collecting any failures without stopping
  for file in "${priority_files[@]}"; do
    bash "$file" || failed_scripts+=("$file")
  done

  # Find all update.bash files at the root level of each tool directory (except @new and @archive) and sort by parent directory name
  update_files=$(find "${DOTFILES}/tools" -maxdepth 2 -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "${file_name}" -print | sort -t/ -k5)

  # Filter out priority files from the list
  for file in "${priority_files[@]}"; do
    update_files=$(echo "$update_files" | grep -v "^$file$")
  done

  # Execute the remaining update.bash files, collecting any failures without stopping
  for file in $update_files; do
    bash "$file" || failed_scripts+=("$file")
  done

  # Summarise any failures at the end for visibility
  if [[ ${#failed_scripts[@]} -gt 0 ]]; then
    error "❌ Some updates failed"
    for file in "${failed_scripts[@]}"; do
      printf "  - %s\n" "$(basename "$(dirname "$file")")" >&2
    done
    printf "\n" >&2
  fi
}

main "$@"
