#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📊 Updating btop"
brew bundle --file="${DOTFILES}/tools/btop/Brewfile"

debug "🔗 Symlinking btop configuration"
bash "${DOTFILES}/tools/btop/link.bash"
