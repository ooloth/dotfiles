#!/usr/bin/env bash
set -euo pipefail

# TODO: change tool name + update TOOL_* variables in utils.bash
source "${DOTFILES}/tools/@new/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

# TODO: change update command + version command
update_or_install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool upgrade ${TOOL_LOWER}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${TOOL_LOWER} --version" \
  "parse_version"
