#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/lazygit/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/config.yml" "${TOOL_CONFIG_DIR}"
