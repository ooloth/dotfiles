#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🟢 Installing Node"
latest_node_version="$(fnm ls-remote | tail -n 1)"
fnm install "${latest_node_version}" --corepack-enabled

debug "🟢 Setting Node ${latest_node_version} as the default version"
fnm default "${latest_node_version}"

debug "🟢 Using Node ${latest_node_version} for this shell"
fnm use "${latest_node_version}"
