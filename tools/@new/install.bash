#!/usr/bin/env bash
set -euo pipefail

# TODO: update names
tool_lower="x"
tool_upper="X"

info "📊 Installing ${tool_lower}"

if have "$tool_lower"; then
  info "✅ ${tool_upper} is already installed"
  exit 0
else
  TODO: update install command
  uv tool install "$tool_lower"
fi

# Symlink config files
source "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash"

# Confirm installation
exec "${SHELL}" -l

if ! have "$tool_lower"; then
  error "❌ $tool_upper command not found"
  exit 1
fi

debug "🚀 ${tool_upper} is installed"
