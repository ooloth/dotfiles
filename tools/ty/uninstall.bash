#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/ty/utils.bash"
source "${DOTFILES}/features/uninstall/utils.bash"

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool uninstall ${TOOL_PACKAGE}"
