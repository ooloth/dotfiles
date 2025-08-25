#!/usr/bin/env bash
set -euo pipefail

# TODO: Install if missing
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

info "🐍 Updating uv and its tools"

uv self update --quiet
uv tool upgrade --all

debug "🚀 All uv tools are up to date"
