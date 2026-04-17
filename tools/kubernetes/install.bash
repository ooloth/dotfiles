#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "☸️  Installing kubernetes tools"
brew bundle --file="${DOTFILES}/tools/kubernetes/Brewfile"

debug "🔗 Symlinking kubernetes configuration"
bash "${DOTFILES}/tools/kubernetes/symlinks/link.bash"
