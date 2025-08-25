#!/usr/bin/env bash
set -euo pipefail

# TODO: Uninstall if present
# TODO: Delete configuration file symlinks (NOT the dotfiles)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

info "🗑️ Uninstalling visidata"

uv tool uninstall visidata

debug "🚀 Visidata has been uninstalled"
