#!/usr/bin/env zsh

source "$DOTFILES/config/zsh/utils.zsh"
info "🧃 Updating neovim dependencies"

printf "😺 Updating vim-kitty-navigator\n"
git -C "$HOME/Repos/knubie/vim-kitty-navigator" pull;
