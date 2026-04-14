#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🚛 Updating k9s"

debug "🔗 Symlinking k9s configuration"
bash "${DOTFILES}/tools/k9s/symlinks/link.bash"
