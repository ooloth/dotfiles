#!/usr/bin/env bash

source "${DOTFILES}/tools/bash/utils.bash"

info "🔋 Updating executable permissions"

files_names=(
  "install"
  "link"
  "unlink"
  "uninstall"
  "update"
)

# Make all *.bash, *.sh or *.zsh files in any DOTFILES subfolder with a name listed in files_names executable
for name in "${files_names[@]}"; do
  fd "${name}.*" "${DOTFILES}" --type f -e bash -e sh -e zsh -X chmod +x
done

printf "🚀 All scripts are executable\n"
