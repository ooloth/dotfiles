#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📋 Updating Trekker"
bun install --global @obsfx/trekker@latest
bun install --global @obsfx/trekker-dashboard@latest
