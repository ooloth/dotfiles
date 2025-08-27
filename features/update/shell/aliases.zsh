#!/usr/bin/env zsh
# set -euo pipefail

alias symlinks="bash ${DOTFILES}/features/update/symlinks.bash"

u() {
  local tool="$1"

  if [[ ! -z "$tool" ]]; then
    # If a specific tool was provided, jsut update that tool
    bash "${DOTFILES}/features/update/tools.bash" "$tool";
  else
    # Otherwise, update all tools
    bash "${DOTFILES}/features/update/tools.bash";
    zsh "${DOTFILES}/features/update/tools.zsh";
  fi
}
