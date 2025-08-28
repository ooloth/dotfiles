#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/uv/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "${TOOL_COMMAND} self update" \
  "${TOOL_COMMAND} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
