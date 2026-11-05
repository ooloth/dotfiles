#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "📊 Updating btop"
brew bundle --file="${DOTFILES}/tools/btop/Brewfile"

debug "🔗 Symlinking btop configuration"
run_link_step "${DOTFILES}/tools/btop/link.bash"
