#!/usr/bin/env bash
set -euo pipefail

# TODO: Install if missing
# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

info "📊 Installing visidata as a uv tool"

uv tool install visidata

debug "🚀 Visidata is installed and configured"
