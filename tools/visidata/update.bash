#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/visidata/utils.bash"

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool upgrade ${TOOL_PACKAGE}" \
  "${TOOL_PACKAGE} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
