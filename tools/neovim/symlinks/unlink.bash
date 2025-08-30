#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/neovim/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"

debug "🔗 Removing symlinked config files"

trash "${HOMECONFIG}/nvim"
trash "${HOMECONFIG}/nvim-ide"
trash "${HOMECONFIG}/nvim-kitty-scrollback"
