#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "📋 Updating Trekker"
bun install --global @obsfx/trekker@latest
bun install --global @obsfx/trekker-dashboard@latest
