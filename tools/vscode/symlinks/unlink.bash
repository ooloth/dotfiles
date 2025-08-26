#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/vscode/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

rm "${TOOL_CONFIG_DIR}/keybindings.json"
rm "${TOOL_CONFIG_DIR}/settings.json"
rm "${TOOL_CONFIG_DIR}/snippets"
