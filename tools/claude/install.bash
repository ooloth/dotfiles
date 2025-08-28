#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/claude/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "npm install --global ${TOOL_PACKAGE}@latest" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_COMMAND} --version" \
  "parse_version"
