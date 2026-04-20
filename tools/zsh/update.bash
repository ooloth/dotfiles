#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📁 Updating zsh"
brew bundle --file="${DOTFILES}/tools/zsh/Brewfile"

debug "🔗 Symlinking zsh configuration"
bash "${DOTFILES}/tools/zsh/link.bash"
