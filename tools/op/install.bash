#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🔐 Installing 1Password CLI"
brew bundle --file="${DOTFILES}/tools/op/Brewfile"
