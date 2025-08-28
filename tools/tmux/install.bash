#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/tmux/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE} " \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"

if [[ ! -d "${TPM_DIR}" ]]; then
  info "${TOOL_EMOJI} Installing tmux's plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi

info "${TOOL_EMOJI} Installing ${TOOL_LOWER}'s plugins"
"${TPM}/install_plugins"
