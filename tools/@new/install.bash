#!/usr/bin/env bash
set -euo pipefail

# TODO: change tool name + update TOOL_* variables in utils.bash
source "${DOTFILES}/tools/@new/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# TODO: change install command + version command
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool install ${TOOL_LOWER}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_LOWER} --version" \
  "parse_version"
