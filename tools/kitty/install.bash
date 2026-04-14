#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🐱 Installing kitty"
brew bundle --file="${DOTFILES}/tools/kitty/Brewfile"

debug "🔗 Symlinking kitty configuration"
bash "${DOTFILES}/tools/kitty/symlinks/link.bash"
