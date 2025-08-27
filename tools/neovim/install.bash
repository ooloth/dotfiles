#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/homebrew/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"

info "${TOOL_EMOJI} Installing ${TOOL_LOWER} homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  if ! is_brew_formula_installed "${formula}"; then
    debug "🍺 Installing ${formula} with homebrew"
    brew install "${formula}"
  else
    printf "✅ ${formula} is already installed\n"
  fi
done

info "${TOOL_EMOJI} Installing ${TOOL_LOWER} npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  if ! is_global_npm_package_installed "${package}"; then
    debug "📦 Installing ${package} with npm"
    npm install -g "${package}"
  else
    printf "✅ ${package} is already installed\n"
  fi
done

info "${TOOL_EMOJI} Restoring locked Lazy plugin versions"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa

debug "🚀 All ${TOOL_UPPER} dependencies are up to date"
