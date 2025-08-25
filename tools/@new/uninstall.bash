#!/usr/bin/env bash
set -euo pipefail

# TODO: uninstall commands
# TODO: Skip if no longer present
# TODO: Delete configuration file symlinks (NOT the dotfiles)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

printf "🗑️ Uninstalling X...\n"
source "${DOTFILES}/X/shell/variables.zsh"

printf "🗑️ Unlinking X configuration files...\n"
source "${DOTFILES}/X/symlinks/unlink.bash"

printf "\n🚀 X has been uninstalled\n"
