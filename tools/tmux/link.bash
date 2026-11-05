#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/gitmux.conf" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/tmux.conf" "${TOOL_CONFIG_DIR}"
