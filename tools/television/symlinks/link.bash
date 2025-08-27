#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/television/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/config.toml" "${TOOL_CONFIG_DIR}"
