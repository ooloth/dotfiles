#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🐚 Uninstalling zsh"
brew bundle list --file="${DOTFILES}/tools/zsh/Brewfile" | while IFS= read -r formula; do
  brew uninstall --formula "${formula}"
done

debug "🔗 Unlinking zsh configuration"
bash "${DOTFILES}/tools/zsh/symlinks/unlink.bash"
