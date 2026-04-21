#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/node/utils.bash" # source last to avoid env var overrides

# Install node, but only update npm to avoid messing with project node versions
update_and_symlink \
  "npm" \
  "npm" \
  "npm" \
  "📦" \
  "npm install --global npm@latest" \
  "npm --version" \
  "" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/link.bash"
