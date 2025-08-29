#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash"
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
  debug "${TOOL_EMOJI} Installing tpm plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi

debug "${TOOL_EMOJI} Installing all tpm plugins"
"${TPM}/install_plugins"

debug "${TOOL_EMOJI} Installing all homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  ensure_brew_formula_installed "${formula}"
done

debug "🚀 All ${TOOL_UPPER} dependencies have been installed"
