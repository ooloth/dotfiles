#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🌐 Installing Tailscale"
brew bundle --file="${DOTFILES}/tools/tailscale/Brewfile"
