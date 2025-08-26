#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/powerlevel10k/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/p10k.zsh" "${TOOL_CONFIG_DIR}"
