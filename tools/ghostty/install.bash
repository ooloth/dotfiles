#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "👻 Installing ghostty"
brew bundle --file="${DOTFILES}/tools/ghostty/Brewfile"
