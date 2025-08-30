#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

trash "${TOOL_CONFIG_DIR}/.hushlogin"
trash "${TOOL_CONFIG_DIR}/.zshenv"
trash "${TOOL_CONFIG_DIR}/.zshrc"
