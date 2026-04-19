#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/sesh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/sesh.toml" "${TOOL_CONFIG_DIR}"
