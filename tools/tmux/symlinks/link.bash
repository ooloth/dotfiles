#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/tmux/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TMUX_LOWER}/config/battery.sh" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TMUX_LOWER}/config/gitmux.conf" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TMUX_LOWER}/config/tmux.conf" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TMUX_LOWER}/config/tmux.terminfo" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TMUX_LOWER}/config/xterm-256color-italic.terminfo" "${TOOL_CONFIG_DIR}"
