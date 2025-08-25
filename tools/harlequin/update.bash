#!/usr/bin/env bash
set -euo pipefail

# TODO: Skip if found
# TODO: Otherwise, update
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

info "🤡 Updating harlequin"

uv tool upgrade harlequin

debug "🚀 Harlequin is up to date"
