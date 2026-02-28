#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Updating codex"
brew bundle --file="${DOTFILES}/tools/codex/Brewfile"
