#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

info "🪟 Installing tmux"
if [[ ! -d "${TPM_DIR}" ]]; then
  debug "📦 Cloning tpm plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi
