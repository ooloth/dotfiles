#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/vscode/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

trash "${TOOL_CONFIG_DIR}/keybindings.json"
trash "${TOOL_CONFIG_DIR}/settings.json"
trash "${TOOL_CONFIG_DIR}/snippets"
