#!/usr/bin/env bash
set -euo pipefail

# TODO: Update tool
# TODO: Install if missing
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

printf "🥁 Updating X...\n"
source "${DOTFILES}/X/shell/variables.zsh"

printf "🔗 Symlinking X configuration files...\n"
source "${DOTFILES}/X/symlinks/link.bash"

printf "\n🚀 X is up to date\n"
