#!/usr/bin/env bash
set -euo pipefail

# TODO: Install command
# TODO: Skip if already found and up to date
# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

printf "🥁 Installing and configuring X...\n"
source "${DOTFILES}/X/shell/variables.zsh"

printf "🔗 Symlinking X configuration files...\n"
source "${DOTFILES}/X/symlinks/link.bash"

printf "🎉 X is installed and configured\n"
