#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

symlink "${DOTFILES}/tools/kitty/config/colorscheme" "${HOME}/.config/kitty"
symlink "${DOTFILES}/tools/kitty/config/kitty.conf" "${HOME}/.config/kitty"
