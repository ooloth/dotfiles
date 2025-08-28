#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/homebrew/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew uninstall --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"

info "${TOOL_EMOJI} Installing ${TOOL_LOWER} homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  brew uninstall --formula "${formula}"
done

info "${TOOL_EMOJI} Installing ${TOOL_LOWER} npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  npm uninstall -g "${package}"
done

debug "🚀 All ${TOOL_UPPER} dependencies have been uninstalled"
