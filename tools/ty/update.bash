#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🍵 Updating ty"
uv tool install --upgrade ty
