#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"
source "${DOTFILES}/tools/vscode/utils.bash"

symlink "${DOTFILES}/tools/vscode/config/keybindings.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/vscode/config/settings.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/vscode/config/snippets" "${TOOL_CONFIG_DIR}"
