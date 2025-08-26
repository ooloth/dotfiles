#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/node/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

if is_work; then
  symlink "${DOTFILES}/tools/node/config/.npmrc" "${HOME}/.config/npm"
else
  printf "✅ No configuration files to symlink\n"
fi
