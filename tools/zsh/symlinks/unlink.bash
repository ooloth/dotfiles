#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

# TODO: confirm this removes the files safely (not just the symlinks)
# TODO: would I ever want to do this for zsh?
rm "${TOOL_CONFIG_DIR}/.hushlogin"
rm "${TOOL_CONFIG_DIR}/.zshenv"
rm "${TOOL_CONFIG_DIR}/.zshrc"
