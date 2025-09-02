#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🪟 Uninstalling sesh"
brew bundle list --file="${DOTFILES}/tools/sesh/Brewfile" | while IFS= read -r formula; do
  brew uninstall --formula "${formula}"
done

debug "🔗 Unlinking sesh configuration"
bash "${DOTFILES}/tools/sesh/symlinks/unlink.bash"
