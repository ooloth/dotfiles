#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/gh/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/gh/config/config.yml" "${TOOL_CONFIG_DIR}"
