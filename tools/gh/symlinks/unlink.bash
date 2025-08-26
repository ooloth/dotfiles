#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/gh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

debug "🔗 Removing symlinked config files"

# TODO: confirm this removes the whole directory safely (not just the symlink)
rm -r "${TOOL_CONFIG_DIR}"
