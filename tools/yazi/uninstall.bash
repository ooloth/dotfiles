#!/usr/bin/env bash
set -euo pipefail

info "📁 Uninstalling yazi"
brew bundle list --file="${DOTFILES}/tools/yazi/Brewfile" | while IFS= read -r formula; do
  brew uninstall --formula "${formula}"
done

debug "🔗 Unlinking yazi configuration"
bash "${DOTFILES}/tools/yazi/symlinks/unlink.bash"
