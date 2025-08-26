#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/symlinks.bash"

symlink "${DOTFILES}/tools/visidata/config/config.py" "${HOME}/.config/visidata"
