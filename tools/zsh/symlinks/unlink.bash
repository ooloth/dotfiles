#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

rm "${TOOL_CONFIG_DIR}/.hushlogin"
rm "${TOOL_CONFIG_DIR}/.zshenv"
rm "${TOOL_CONFIG_DIR}/.zshrc"
