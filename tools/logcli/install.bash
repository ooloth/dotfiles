#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📊 Installing logcli"
brew bundle --file="${DOTFILES}/tools/logcli/Brewfile"
