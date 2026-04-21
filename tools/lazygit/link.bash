#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/lazygit/config/config.yml" "${HOME}/.config/lazygit"
