#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🧑‍🍳 Installing mise"
curl https://mise.run | sh
