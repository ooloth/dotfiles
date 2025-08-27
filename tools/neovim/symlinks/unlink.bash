#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/neovim/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"

debug "🔗 Removing symlinked config files"

rm -rf "${HOMECONFIG}/nvim"
rm -rf "${HOMECONFIG}/nvim-ide"
rm -rf "${HOMECONFIG}/nvim-kitty-scrollback"
