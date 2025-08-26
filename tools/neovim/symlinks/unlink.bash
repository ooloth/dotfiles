#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/neovim/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

rm "${HOMECONFIG}/nvim"
rm "${HOMECONFIG}/nvim-ide"
rm "${HOMECONFIG}/nvim-kitty-scrollback"
