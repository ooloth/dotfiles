#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

config_dir="${HOME}/.config/yazi"

symlink "${DOTFILES}/tools/yazi/config/keymap.toml" "${config_dir}"
symlink "${DOTFILES}/tools/yazi/config/theme.toml" "${config_dir}"
symlink "${DOTFILES}/tools/yazi/config/yazi.toml" "${config_dir}"
