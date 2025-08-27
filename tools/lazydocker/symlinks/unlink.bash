#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/lazydocker/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"
rm -rf "${TOOL_CONFIG_DIR}"
