#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/kitty/config/colorscheme" "${HOME}/.config/kitty"
symlink "${DOTFILES}/tools/kitty/config/kitty.conf" "${HOME}/.config/kitty"
