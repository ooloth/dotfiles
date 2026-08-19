#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🟢 Installing Node"
latest_node_version="$(fnm ls-remote | tail -n 1)"
fnm install "${latest_node_version}"

debug "🟢 Setting Node ${latest_node_version} as the default version"
fnm default "${latest_node_version}"

debug "🟢 Using Node ${latest_node_version} for this shell"
fnm use "${latest_node_version}"

debug "🟢 Installing Corepack (not bundled with Node ≥25; can be pruned by npm global upgrades on earlier versions)"
npm install --global corepack

debug "🟢 Enabling Corepack shims for yarn/pnpm"
corepack enable
