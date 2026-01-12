#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Installing just"
brew bundle --file="${DOTFILES}/tools/just/Brewfile"
