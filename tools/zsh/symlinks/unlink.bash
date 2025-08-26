#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

# TODO: confirm this removes the files safely (not just the symlinks)
# TODO: would I ever want to do this for zsh?
rm "${HOME}/.hushlogin"
rm "${HOME}/.zshenv"
rm "${HOME}/.zshrc"
