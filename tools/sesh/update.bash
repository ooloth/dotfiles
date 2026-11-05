#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🪟 Updating sesh"
brew bundle --file="${DOTFILES}/tools/sesh/Brewfile"

debug "🚀 Sesh is up-to-date"
