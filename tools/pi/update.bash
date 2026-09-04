#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🥧 Updating Pi"

# Remove any leftover bin from the pre-rename package name so it doesn't collide
# with the new package's bin symlink (npm won't overwrite a bin it doesn't own)
npm uninstall --global @mariozechner/pi-coding-agent 2>/dev/null || true

npm install --global @earendil-works/pi-coding-agent@latest
