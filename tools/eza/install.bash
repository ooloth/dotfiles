#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📁 Installing eza"
brew bundle --file="${DOTFILES}/tools/eza/Brewfile"
