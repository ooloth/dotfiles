#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/neovim/utils.bash"

info "🦸 Uninstalling Neovim"

debug "📦 Uninstalling uv tool dependencies"
for package in "${TOOL_UV_DEPENDENCIES[@]}"; do
  uv tool uninstall "${package}"
done

debug "📦 Uninstalling global npm dependencies"
for package in "${TOOL_NPM_DEPENDENCIES[@]}"; do
  npm uninstall -g "${package}"
done
