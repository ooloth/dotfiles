#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📋 Uninstalling Trekker"
bun remove --global @obsfx/trekker
bun remove --global @obsfx/trekker-dashboard 2>/dev/null || true
