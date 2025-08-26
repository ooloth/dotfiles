#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/yazi/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/yazi/config/keymap.toml" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/yazi/config/theme.toml" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/yazi/config/yazi.toml" "${TOOL_CONFIG_DIR}"
