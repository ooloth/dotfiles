#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if is_work; then
  # See: https://python.prod.rxrx.io/UV-Adoption-Guide
  info "🐍 Installing uv (work)"
  curl -LsSf https://python.prod.rxrx.io/rxrx-setup-uv.sh | sh
else
  # See: https://docs.astral.sh/uv/getting-started/installation/
  info "🐍 Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
