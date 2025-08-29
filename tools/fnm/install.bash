#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/fnm/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE}" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"
