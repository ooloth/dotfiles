#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Updating just"
brew bundle --file="${DOTFILES}/tools/just/Brewfile"
