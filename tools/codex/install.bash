#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Installing codex"
brew bundle --file="${DOTFILES}/tools/codex/Brewfile"
