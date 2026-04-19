#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/github/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/github/config/config.yml" "${TOOL_CONFIG_DIR}"
