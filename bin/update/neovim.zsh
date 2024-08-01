#!/usr/bin/env zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🧃 Updating neovim dependencies"

printf "😺 Updating vim-kitty-navigator\n"
git -C "$HOME/Repos/knubie/vim-kitty-navigator" pull;
