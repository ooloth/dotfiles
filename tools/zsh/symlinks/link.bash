#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/zsh/config/.hushlogin" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/zsh/config/.zshenv" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/zsh/config/.zshrc" "${TOOL_CONFIG_DIR}"
