#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/uninstall/utils.bash"
source "${DOTFILES}/tools/trekker/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "bun remove --global ${TOOL_PACKAGE}; bun remove --global @obsfx/trekker-dashboard 2>/dev/null || true"
