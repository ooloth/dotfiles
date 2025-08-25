#!/usr/bin/env zsh
# set -euo pipefail

u() {
  bash "${DOTFILES}/features/update/tools.bash";
  zsh "${DOTFILES}/features/update/tools.zsh";
}
