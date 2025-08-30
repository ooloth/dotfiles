#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE} " \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

if [[ ! -d "${TPM_DIR}" ]]; then
  debug "📦 Installing tpm plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi

debug "📦 Installing tpm plugins"
"${TPM}/install_plugins"

debug "📦 Installing homebrew dependencies"
brew bundle --file="${DOTFILES}/tools/tmux/Brewfile"

debug "🚀 All ${TOOL_UPPER} dependencies have been installed"
