#!/usr/bin/env bash
set -euo pipefail

printf "✅ No configuration files to unlink\n"

# TODO: confirm this removes the whole directory safely (not just the symlink)
# source "${DOTFILES}/tools/@new/utils.bash"
# source "${DOTFILES}/tools/bash/utils.bash"
# debug "🔗 Removing symlinked config files"
# rm -r "${TOOL_CONFIG_DIR}"
