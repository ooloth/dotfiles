#!/usr/bin/env zsh
# set -euo pipefail

alias symlinks="bash ${DOTFILES}/features/update/symlinks.bash"

u() {
  local tool="$1"

  bash "${DOTFILES}/features/update/tools.bash" "$tool";
  zsh "${DOTFILES}/features/update/tools.zsh";
}
