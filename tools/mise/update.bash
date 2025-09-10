#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🧑‍🍳 Updating mise"

# See: https://mise.jdx.dev/cli/self-update.html#mise-self-update
mise self-update
