#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/neovim/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"

symlink "${DOTFILES}/tools/neovim/config/nvim/init.lua" "${HOMECONFIG}/nvim"
symlink "${DOTFILES}/tools/neovim/config/nvim-ide/init.lua" "${HOMECONFIG}/nvim-ide"
symlink "${DOTFILES}/tools/neovim/config/nvim-ide/lazy-lock.json" "${HOMECONFIG}/nvim-ide"
symlink "${DOTFILES}/tools/neovim/config/nvim-kitty-scrollback/init.lua" "${HOMECONFIG}/nvim-kitty-scrollback"
