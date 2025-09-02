#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew uninstall --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"

debug "📦 Uninstalling homebrew dependencies"
brew bundle list --file="${DOTFILES}/tools/${TOOL_LOWER}/Brewfile" | while IFS= read -r formula; do
  brew uninstall --formula "${formula}"
done

debug "📦 Uninstalling global npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  npm uninstall -g "${package}"
done

debug "🚀 All ${TOOL_UPPER} dependencies have been uninstalled"
