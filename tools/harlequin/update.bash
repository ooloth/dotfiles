#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/harlequin/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

update_or_install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool upgrade ${TOOL_LOWER}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${TOOL_LOWER} --version" \
  "parse_version"
