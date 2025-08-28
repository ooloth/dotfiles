#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/uninstall/utils.bash"
source "${DOTFILES}/tools/eza/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew uninstall --formula ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"
