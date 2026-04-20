#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

CONFIG_REPO="ooloth/config.nvim"
LOCAL_REPO_PATH="${HOME}/Repos/${CONFIG_REPO}"

info "🦸 Installing Neovim"
if [[ ! -d "${LOCAL_REPO_PATH}" ]]; then
  mkdir -p "${LOCAL_REPO_PATH}"
  git clone "git@github.com:${CONFIG_REPO}.git" "${LOCAL_REPO_PATH}"
fi
