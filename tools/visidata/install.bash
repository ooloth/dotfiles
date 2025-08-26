#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/visidata/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

install_and_symlink \
  "${TOOL_UPPER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool install ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_LOWER} --version" \
  "parse_version"
