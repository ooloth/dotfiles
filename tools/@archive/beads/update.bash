#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📿 Updating beads"
brew bundle --file="${DOTFILES}/tools/beads/Brewfile"
