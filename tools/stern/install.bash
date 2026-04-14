#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📋 Installing stern"
brew bundle --file="${DOTFILES}/tools/stern/Brewfile"
