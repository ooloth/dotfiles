#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"
source "${DOTFILES}/tools/node/utils.bash"

# Work machines also need the private work registry, so each machine type gets its own file
if is_work; then
  symlink "${DOTFILES}/tools/node/config/work/.npmrc" "${HOME}/.config/npm"
else
  symlink "${DOTFILES}/tools/node/config/personal/.npmrc" "${HOME}/.config/npm"
fi
