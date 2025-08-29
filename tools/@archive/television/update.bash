#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/@archive/television/utils.bash"

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE} && ${TOOL_COMMAND} update-channels" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
