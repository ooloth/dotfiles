#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤡 Updating Harlequin"
uv tool install --upgrade harlequin
