#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🪟 Installing sesh"
brew bundle --file="${DOTFILES}/tools/sesh/Brewfile"

debug "🚀 Sesh is installed"
