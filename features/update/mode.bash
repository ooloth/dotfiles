#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🔋 Updating executable permissions"

file_names=(
  "install"
  "link"
  "unlink"
  "uninstall"
  "update"
)

# Make all *.bash, *.sh or *.zsh files in any DOTFILES subfolder with a name listed in files_names executable
for name in "${file_names[@]}"; do
  fd "${name}.*" "${DOTFILES}" --type f -e bash -e sh -e zsh -X chmod +x
done

printf "🚀 All scripts are executable\n"
