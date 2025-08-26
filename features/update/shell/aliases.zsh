#!/usr/bin/env zsh
# set -euo pipefail

u() {
  local tool="$1"

  if [[ ! -z "$tool" ]]; then
    bash "${DOTFILES}/features/update/tools.bash" "$tool";
  else
    bash "${DOTFILES}/features/update/tools.bash";
    zsh "${DOTFILES}/features/update/tools.zsh";
  fi
}
