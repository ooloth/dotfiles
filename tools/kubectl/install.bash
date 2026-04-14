#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "☸️  Installing kubectl"
brew bundle --file="${DOTFILES}/tools/kubectl/Brewfile"
