#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/neovim/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

rm -f "${HOMECONFIG}/nvim"
rm -f "${HOMECONFIG}/nvim-ide"
rm -f "${HOMECONFIG}/nvim-kitty-scrollback"
