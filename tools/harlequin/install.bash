#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/harlequin/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_EMOJI}" \
  "uv tool install ${TOOL_PACKAGE}" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_PACKAGE} --version" \
  "parse_version"
