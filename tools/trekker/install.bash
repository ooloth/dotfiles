#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/trekker/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "bun install --global ${TOOL_PACKAGE}" \
  "${TOOL_COMMAND} --version" \
  "parse_version"

if ! have trekker-dashboard; then
  debug "📋 Installing trekker-dashboard"
  bun install --global @obsfx/trekker-dashboard
fi
