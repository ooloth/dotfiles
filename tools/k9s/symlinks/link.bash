#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/k9s/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/k9s/config/aliases.yaml" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/k9s/config/config.yaml" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/k9s/config/hotkeys.yaml" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/k9s/config/skins" "${TOOL_CONFIG_DIR}"
