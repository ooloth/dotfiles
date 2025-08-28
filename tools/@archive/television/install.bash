#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/television/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# See: https://alexpasmantier.github.io/television/docs/Users/installation/
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE} && ${TOOL_COMMAND} update-channels" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
