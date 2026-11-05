#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "📁 Updating zsh"
brew bundle --file="${DOTFILES}/tools/zsh/Brewfile"

debug "🔗 Symlinking zsh configuration"
run_link_step "${DOTFILES}/tools/zsh/link.bash"
