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

info "${TOOL_EMOJI} Installing ${TOOL_LOWER}'s homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  ensure_brew_formula_installed "${formula}"
done

info "${TOOL_EMOJI} Installing ${TOOL_LOWER}'s npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  ensure_global_npm_package_installed "${package}"
done

info "${TOOL_EMOJI} Installing config.nvim"

CONFIG_REPO="ooloth/config.nvim"
LOCAL_REPO_PATH="$HOME/Repos/$CONFIG_REPO"

if [ ! -d "${LOCAL_REPO_PATH}" ]; then
  mkdir -p "${LOCAL_REPO_PATH}"
  git clone "git@github.com:${CONFIG_REPO}.git" "${LOCAL_REPO_PATH}"
else
  printf "✅ config.nvim is already installed\n"
fi

info "${TOOL_EMOJI} Installing Lazy plugin versions"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa

printf "\n\n🚀 All ${TOOL_UPPER} dependencies have been installed\n"
