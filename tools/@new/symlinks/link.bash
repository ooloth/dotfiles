#!/usr/bin/env bash
set -euo pipefail

if [ "${VERBOSE:-false}" = true ]; then
  printf "✅ No configuration files to symlink\n"
fi

# source "${DOTFILES}/tools/@new/utils.bash"
# source "${DOTFILES}/tools/bash/utils.bash"

# symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/config.yaml" "${TOOL_CONFIG_DIR}"
