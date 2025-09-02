#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

info "🪟 Installing tmux"
brew bundle --file="${DOTFILES}/tools/tmux/Brewfile"

if [[ ! -d "${TPM_DIR}" ]]; then
  debug "📦 Installing tpm plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi

debug "📦 Installing tpm plugins"
"${TPM}/install_plugins"

debug "🚀 All ${TOOL_UPPER} dependencies have been installed"
