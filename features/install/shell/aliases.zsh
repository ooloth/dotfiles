#!/usr/bin/env zsh
# set -euo pipefail

i() {
  local tool="$1"

  bash "${DOTFILES}/features/install/tools.bash" "$tool";

  printf "🔁 Reloading shell\n"
  exec -l "${SHELL}"
}
