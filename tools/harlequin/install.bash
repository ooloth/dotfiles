#!/usr/bin/env bash
set -euo pipefail

# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

info "🤡 Installing harlequin as a uv tool"

uv tool install harlequin

debug "🚀 Harlequin is installed and configured"
