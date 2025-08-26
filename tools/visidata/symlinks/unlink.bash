#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"
rm -r "${HOME}/.config/visidata"
