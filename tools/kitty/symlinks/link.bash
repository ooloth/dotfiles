#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/kitty/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/colorscheme" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/kitty.conf" "${TOOL_CONFIG_DIR}"
