#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🧑‍🍳 Uninstalling mise"

# See: https://mise.jdx.dev/installing-mise.html#uninstalling
mise implode
