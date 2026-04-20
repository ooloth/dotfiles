#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/ghostty/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/config" "${TOOL_CONFIG_DIR}"
