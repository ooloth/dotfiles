#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/ghostty/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"
rm -rf "${TOOL_CONFIG_DIR}"
