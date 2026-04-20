#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if is_work; then
  symlink "${DOTFILES}/tools/kubernetes/config/aliases.yaml" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/config.yaml" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/hotkeys.yaml" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/skins" "${HOME}/.config/k9s"
  symlink "${DOTFILES}/tools/kubernetes/config/clusters" "${HOME}/.config/k9s"
fi
