#!/usr/bin/env bash
set -euo pipefail

# TODO: change tool name + update TOOL_* variables in utils.bash
source "${DOTFILES}/tools/@new/utils.bash"
source "${DOTFILES}/features/uninstall/utils.bash"

# TODO: change uninstall command
uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool uninstall ${TOOL_LOWER}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"
