#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash" # source last to avoid env var overrides

info "🦸 Installing neovim"
brew bundle --file="${DOTFILES}/tools/neovim/Brewfile"

debug "🔗 Symlinking neovim configuration"
bash "${DOTFILES}/tools/neovim/symlinks/link.bash"

debug "📦 Installing global npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  ensure_global_npm_package_installed "${package}"
done

debug "🦸 Installing config.nvim"

CONFIG_REPO="ooloth/config.nvim"
LOCAL_REPO_PATH="$HOME/Repos/$CONFIG_REPO"

if [ ! -d "${LOCAL_REPO_PATH}" ]; then
  mkdir -p "${LOCAL_REPO_PATH}"
  git clone "git@github.com:${CONFIG_REPO}.git" "${LOCAL_REPO_PATH}"
else
  printf "✅ config.nvim is already installed\n"
fi

debug "📦 Installing Lazy plugin versions"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa

debug "🚀 All ${TOOL_UPPER} dependencies have been installed"
