#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/kitty/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/kitty/config/colorscheme" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/kitty/config/kitty.conf" "${TOOL_CONFIG_DIR}"
