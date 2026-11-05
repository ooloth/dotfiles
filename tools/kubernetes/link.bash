#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

if is_work; then
  symlink "${DOTFILES}/tools/kubernetes/config/k9s/aliases.yaml" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/k9s/config.yaml" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/k9s/skins" "${HOME}/.config/k9s"
fi
