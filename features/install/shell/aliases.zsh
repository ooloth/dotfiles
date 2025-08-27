#!/usr/bin/env zsh
# set -euo pipefail

i() {
  local tool="$1"

  if [[ ! -z "$tool" ]]; then
    bash "${DOTFILES}/features/install/tools.bash" "$tool";
  else
    bash "${DOTFILES}/features/install/tools.bash";
  fi
}
