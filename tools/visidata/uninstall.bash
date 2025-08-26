#!/usr/bin/env bash
set -euo pipefail

# TODO: Delete configuration file symlinks (NOT the dotfiles)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

info "🗑️ Uninstalling visidata"

uv tool uninstall visidata

# Confirm uninstallation
exec "${SHELL}" -l

if have vd; then
  error "❌ Visidata command still found"
  exit 1
fi

# Remove symlinks
source "${DOTFILES}/tools/visidata/symlinks/unlink.bash"

debug "🚀 Visidata has been uninstalled"
