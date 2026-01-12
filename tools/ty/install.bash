#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/ty/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool install ${TOOL_PACKAGE}" \
  "${TOOL_PACKAGE} --version" \
  "parse_version"
