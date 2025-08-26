#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/git/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"
rm "${TOOL_CONFIG_DIR}"
