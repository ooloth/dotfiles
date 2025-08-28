#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
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
  info "${TOOL_EMOJI} Installing ${TOOL_LOWER}'s plugin manager"
  git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
fi

info "${TOOL_EMOJI} Installing ${TOOL_LOWER} plugins"
"${TPM}/install_plugins"

info "${TOOL_EMOJI} Installing ${TOOL_LOWER}'s homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  ensure_brew_formula_installed "${formula}"
done

printf "\n🚀 All ${TOOL_UPPER} dependencies have been installed\n"
