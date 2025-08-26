#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/gemini/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# See: https://github.com/google-gemini/gemini-cli?tab=readme-ov-file#-installation
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"
