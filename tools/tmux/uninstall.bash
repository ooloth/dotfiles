#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🪟 Uninstalling tmux"
trash "${HOME}/.config/tmux/plugins/tpm"
