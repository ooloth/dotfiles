#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📊 Uninstalling VisiData"
uv tool uninstall visidata
