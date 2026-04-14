#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🐹 Installing go"
brew bundle --file="${DOTFILES}/tools/go/Brewfile"
