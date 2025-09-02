#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

info "🪟 Updating tmux"
brew bundle --file="${DOTFILES}/tools/tmux/Brewfile"

debug "📦 Updating tpm plugins"
"${TPM}/clean_plugins"
"${TPM}/install_plugins"
"${TPM}/update_plugins" all

# Reload tmux if it's running
if pgrep -q tmux; then
  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  debug "🔁 Reloading ${TOOL_LOWER}"
  tmux source "${TOOL_CONFIG_DIR}/tmux.conf"
fi

debug "🚀 All ${TOOL_UPPER} dependencies are up-to-date"
