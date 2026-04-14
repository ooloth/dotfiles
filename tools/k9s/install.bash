#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🚛 Installing k9s"
brew bundle --file="${DOTFILES}/tools/k9s/Brewfile"

debug "🔗 Symlinking k9s configuration"
bash "${DOTFILES}/tools/k9s/symlinks/link.bash"
