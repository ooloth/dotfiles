#!/usr/bin/env bash
set -euo pipefail

tool_lower="harlequin"
tool_upper="Harlequin"

info "📊 Installing ${tool_lower} as a uv tool"

if have "$tool_lower"; then
  info "✅ ${tool_upper} is already installed"
else
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
