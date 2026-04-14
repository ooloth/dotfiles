#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "✂️  Installing sd"
brew bundle --file="${DOTFILES}/tools/sd/Brewfile"
