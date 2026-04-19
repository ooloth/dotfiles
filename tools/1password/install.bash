#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🔐 Installing 1Password and its CLI"
brew bundle --file="${DOTFILES}/tools/1password/Brewfile"
