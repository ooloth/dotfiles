#!/usr/bin/env bash
set -euo pipefail

# TODO: change tool name + update TOOL_* variables in utils.bash
source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/@new/utils.bash" # source last to avoid env var overrides

# TODO: change update command + version command
update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"
