#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "📁 Updating yazi"
brew bundle --file="${DOTFILES}/tools/yazi/Brewfile"

debug "🔗 Symlinking yazi configuration"
run_link_step "${DOTFILES}/tools/yazi/link.bash"
