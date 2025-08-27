#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/visidata/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool upgrade ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${TOOL_PACKAGE} --version" \
  "parse_version"
