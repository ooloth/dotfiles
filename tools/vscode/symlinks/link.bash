#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/vscode/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/vscode/config/keybindings.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/vscode/config/settings.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/vscode/config/snippets" "${TOOL_CONFIG_DIR}"
