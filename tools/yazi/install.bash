#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📁 Installing yazi"
brew bundle --file="${DOTFILES}/tools/yazi/Brewfile"

debug "🔗 Symlinking yazi configuration"
bash "${DOTFILES}/tools/yazi/symlinks/link.bash"
