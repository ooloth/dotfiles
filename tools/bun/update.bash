#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🍞 Updating bun"
brew bundle --file="${DOTFILES}/tools/bun/Brewfile"
