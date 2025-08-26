#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/visidata/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/visidata/config/config.py" "${TOOL_CONFIG_DIR}"
