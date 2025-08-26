#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🐍 Installing uv"

if have uv; then
  info "✅ uv is already installed"
else
  # See: https://docs.astral.sh/uv/getting-started/installation/
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Symlink config files
source "${DOTFILES}/tools/uv/symlinks/link.bash"

# Confirm installation
exec "${SHELL}" -l

if ! have uv; then
  error "❌ uv command not found"
  exit 1
fi

debug "🚀 uv is installed"
