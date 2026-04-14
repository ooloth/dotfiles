#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🐙 Installing gh"
brew bundle --file="${DOTFILES}/tools/gh/Brewfile"

debug "🔗 Symlinking gh configuration"
bash "${DOTFILES}/tools/gh/symlinks/link.bash"
