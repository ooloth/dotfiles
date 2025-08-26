#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"
VSCODEUSER="$HOME/Library/Application Support/Code/User"

main() {
  local tool="${1:-}"

  info "🔗 Updating symlinks"

  # Remove broken symlinks first
  for dir in "${HOME}" "${HOMECONFIG}" "${VSCODEUSER}"; do
    remove_broken_symlinks "$dir"
  done

  # If a specific tool is provided as an argument, symlink only that tool's configs
  if [[ ! -z "$tool" ]]; then
    bash "${DOTFILES}/tools/${tool}/symlinks/link.bash"
    return 0
  fi

  # Otherwise, symlinks all tool configs with a link.bash script

  # Find all link.bash files in each tool directory (except @new and @archive) and sort by parent directory name
  update_files=$(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "link.bash" -print | sort -t/ -k5)

  # Execute each link.bash file to create the appropriate symlinks
  for file in $update_files; do
    bash "$file"
  done

  debug "🔗 Creating manual symlinks"

  symlink "${DOTFILES}/tools/vscode/config/keybindings.json" "${VSCODEUSER}"
  symlink "${DOTFILES}/tools/vscode/config/settings.json" "${VSCODEUSER}"
  symlink "${DOTFILES}/tools/vscode/config/snippets" "${VSCODEUSER}"

  debug "🎉 All symlinks are up to date"
}

main "$@"
