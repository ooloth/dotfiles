#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"

main() {
  local tool="${1:-}"

  info "🔗 Updating symlinks"

  # Remove broken symlinks first
  local dir
  while IFS= read -r dir; do
    remove_broken_symlinks "${dir}"
  done < <(any_broken_symlink_dirs)
  while IFS= read -r dir; do
    remove_broken_repo_symlinks "${dir}"
  done < <(repo_symlink_dirs)

  # If a specific tool is provided as an argument, symlink only that tool's configs
  if [[ ! -z "${tool}" ]]; then
    bash "${DOTFILES}/tools/${tool}/link.bash"
    return 0
  fi

  # Otherwise, run every tool's link.bash
  local scripts script
  scripts="$(link_scripts)"
  while IFS= read -r script; do
    bash "${script}"
  done <<<"${scripts}"

  debug "🚀 All symlinks are up to date"
}

main "$@"
