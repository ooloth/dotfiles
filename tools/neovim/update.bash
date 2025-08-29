#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash" # source last to avoid env var overrides

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE}" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "📦 Updating homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  ensure_brew_formula_updated "${formula}"
done

debug "📦 Updating global npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  ensure_global_npm_package_updated "${package}"
done

debug "📦 Restoring Lazy plugin versions"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1

debug "🚀 All ${TOOL_UPPER} dependencies are up-to-date"
