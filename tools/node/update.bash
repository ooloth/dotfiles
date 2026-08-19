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

# Keep Corepack present: npm's global upgrade above can prune it since it isn't
# npm-tracked, and Node ≥25 no longer bundles it at all
update_and_symlink \
  "corepack" \
  "corepack" \
  "corepack" \
  "📦" \
  "npm install --global corepack@latest" \
  "corepack --version" \
  "" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/link.bash"
