#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"
trash "${HOME}/.config/mise"
