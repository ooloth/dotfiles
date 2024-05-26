#!/usr/bin/env zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🍱 Installing tmux terminfo updates and tpm"

printf "\nAdding tmux.terminfo"
tic -x "$DOTFILES/tmux/tmux.terminfo"

printf "\nAdding xterm-256color-italic.terminfo"
tic -x "$DOTFILES/tmux/xterm-256color-italic.terminfo"

# TODO: confirm success + handle failure

# Return if tpm is installed
if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
  printf "\n🍱 tpm is already installed\n"
  return
fi

# Otherwise, install
printf "\n🍱 Installing tpm..."

# see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
git clone "git@github.com:tmux-plugins/tpm.git" "$HOME/.config/tmux/plugins/tpm"

printf "\n🚀 Finished installing tpm\n"