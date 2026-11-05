#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🦖 Updating rex"
brew bundle --file="${DOTFILES}/tools/rex/Brewfile"
