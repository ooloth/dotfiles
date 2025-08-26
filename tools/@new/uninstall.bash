#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# TODO: update names
tool_lower="x"
tool_upper="X"

info "🗑️ Uninstalling $tool_lower"

# TODO: update uninstall command
uv tool uninstall "$tool_lower"

# Remove symlinks
source "${DOTFILES}/tools/${tool_lower}/symlinks/unlink.bash"

# Confirm uninstallation
exec "${SHELL}" -l

if have "$tool_lower"; then
  error "❌ $tool_upper command still found"
  exit 1
fi

debug "🚀 $tool_upper has been uninstalled"
