#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/node/utils.bash" # source last to avoid env var overrides

latest_node_version="$(fnm ls-remote | tail -n 1)"

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "fnm install ${latest_node_version} --corepack-enabled" \
  "${TOOL_COMMAND} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "🟢 Setting Node ${latest_node_version} as the default version"
fnm default "${latest_node_version}"

debug "🟢 Using Node ${latest_node_version} for this shell"
fnm use "${latest_node_version}"
