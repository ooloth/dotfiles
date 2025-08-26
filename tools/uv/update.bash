#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/uv/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "${TOOL_PACKAGE} self update" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${TOOL_PACKAGE} --version" \
  "parse_version"
