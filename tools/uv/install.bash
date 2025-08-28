#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/uv/utils.bash"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "${TOOL_INSTALL_COMMAND}" \
  "${TOOL_PACKAGE} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash"
