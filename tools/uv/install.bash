#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if is_work; then
  if [[ -z "${PRIVATE_UV_INSTALLER_URL:-}" ]]; then
    error "PRIVATE_UV_INSTALLER_URL is unset (see private.env.example), so uv can't be installed"
    exit 1
  fi
  info "🐍 Installing uv (work)"
  curl -LsSf "${PRIVATE_UV_INSTALLER_URL}" | sh
else
  # See: https://docs.astral.sh/uv/getting-started/installation/
  info "🐍 Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
