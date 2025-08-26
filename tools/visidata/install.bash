#!/usr/bin/env bash
set -euo pipefail

tool_lower="visidata"
tool_upper="Visidata"

info "📊 Installing ${tool_lower} as a uv tool"

if have "$tool_lower"; then
  info "📦 ${tool_upper} is already installed, skipping"
  exit 0
else
  uv tool install "$tool_lower"
fi

# Confirm installation
exec "${SHELL}" -l

if ! have vd; then
  error "❌ Visidata command not found"
  exit 1
fi

# Symlink config files
source "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash"

debug "🚀 ${tool_upper} is installed"
