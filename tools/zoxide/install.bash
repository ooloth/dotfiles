#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "⚡ Installing zoxide"
brew bundle --file="${DOTFILES}/tools/zoxide/Brewfile"
