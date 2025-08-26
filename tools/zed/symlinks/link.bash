#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/zed/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/keymap.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/settings.json" "${TOOL_CONFIG_DIR}"
