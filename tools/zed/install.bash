#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "⚡ Installing zed"
brew bundle --file="${DOTFILES}/tools/zed/Brewfile"

debug "🔗 Symlinking zed configuration"
bash "${DOTFILES}/tools/zed/symlinks/link.bash"
