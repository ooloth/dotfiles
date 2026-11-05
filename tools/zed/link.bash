#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

symlink "${DOTFILES}/tools/zed/config/keymap.json" "${HOME}/.config/zed"
symlink "${DOTFILES}/tools/zed/config/settings.json" "${HOME}/.config/zed"
