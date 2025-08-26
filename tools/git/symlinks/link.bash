#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/git/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/git/config/config" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/git/config/config.work" "${TOOL_CONFIG_DIR}"
