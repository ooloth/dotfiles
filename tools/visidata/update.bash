#!/usr/bin/env bash
set -euo pipefail

# TODO: Skip installation if found
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

info "📊 Updating visidata"

uv tool upgrade visidata

debug "🚀 Visidata is up to date"
