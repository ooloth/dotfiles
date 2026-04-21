#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" "${HOME}/.config/powerlevel10k"
