#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

TPM_DIR="${HOME}/.config/tmux/plugins/tpm"

info "🪟 Installing tmux"
if [[ ! -d "${TPM_DIR}" ]]; then
  debug "📦 Cloning tpm plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi
