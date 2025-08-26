#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/harlequin/utils.bash"
source "${DOTFILES}/features/uninstall/utils.bash"

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool uninstall ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"
