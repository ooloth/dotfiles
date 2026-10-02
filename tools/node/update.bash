#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/node/utils.bash" # source last to avoid env var overrides

# Keep the default Node on the newest LTS so it never ages out of what npm supports.
# Only the default moves: projects that need another version pin it in .node-version.
info "🟢 Updating the default Node"
lts_node_version="$(latest_lts_node_version)"
fnm install "${lts_node_version}"
fnm default "${lts_node_version}"

# The calling shell's PATH still points at its previous Node, so switch this script
# to the new default before updating the npm that comes with it
eval "$(fnm env --shell bash)"
debug "✅ Default Node is ${lts_node_version}"

npm_version="$(npm_version_supporting_active_node)"

update_and_symlink \
  "npm" \
  "npm" \
  "npm" \
  "📦" \
  "npm install --global npm@${npm_version}" \
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

# Fail after Corepack has been handled, so the end-of-run summary lists node
if [[ "${npm_version}" != "latest" ]]; then
  warn "⚠️ npm@latest does not support Node $(node --version)"
  debug "npm@latest requires Node $(npm view npm@latest engines.node), so npm ${npm_version} was installed instead."
  debug "The default is already the newest LTS, so this clears once npm supports it or a newer LTS ships."
  exit 1
fi
