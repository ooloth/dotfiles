#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🤖 Updating just"
brew bundle --file="${DOTFILES}/tools/just/Brewfile"
