#!/usr/bin/env bash
set -euo pipefail

# See: https://github.com/google-gemini/gemini-cli?tab=readme-ov-file#-installation
source "${DOTFILES}/tools/bash/utils.bash"

info "💎 Installing gemini"
brew bundle --file="${DOTFILES}/tools/gemini/Brewfile"
