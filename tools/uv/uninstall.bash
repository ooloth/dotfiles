#!/usr/bin/env bash
set -euo pipefail

# TODO: Uninstall if present
# TODO: Delete configuration file symlinks (NOT the dotfiles)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

info "🐍 Uninstalling uv"

debug "🧼 Cleaning uv cache and other stored data..."
uv cache clean
rm -r "$(uv python dir)"
rm -r "$(uv tool dir)"

debug "🧼 Uninstalling the uv and uvx binaries..."
rm ~/.local/bin/uv ~/.local/bin/uvx

debug "🚀 uv has been uninstalled"
