#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if [ -e "${HOME}/.config/k9s" ]; then
  debug "🔗 Removing symlinked config files"
  trash "${HOME}/.config/k9s"
fi
