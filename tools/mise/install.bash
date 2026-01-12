#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "👨‍🍳 Installing mise"
brew bundle --file="${DOTFILES}/tools/mise/Brewfile"
