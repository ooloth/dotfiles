#!/usr/bin/env zsh

# Return if installed
if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
  printf "\n🍱 tpm is already installed\n"
  return
fi

# Otherwise, install
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🍱 Installing tpm..."

# see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
git clone "git@github.com:tmux-plugins/tpm.git" "$HOME/.config/tmux/plugins/tpm

printf "\n🚀 Finished installing tpm\n"