#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🦖 Updating rex"
brew bundle --file="${DOTFILES}/tools/rex/Brewfile"
