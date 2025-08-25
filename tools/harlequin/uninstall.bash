#!/usr/bin/env bash
set -euo pipefail

# TODO: Delete configuration file symlinks (NOT the dotfiles copy)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

info "🤡 Uninstalling harlequin"

uv tool uninstall harlequin

debug "🚀 Harlequin has been uninstalled"
