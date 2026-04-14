#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "⚡ Installing fnm"
brew bundle --file="${DOTFILES}/tools/fnm/Brewfile"
