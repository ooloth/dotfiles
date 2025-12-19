#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📿 Installing beads"
brew bundle --file="${DOTFILES}/tools/beads/Brewfile"
