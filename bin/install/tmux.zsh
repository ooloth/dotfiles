#!/usr/bin/env zsh

DOTCONFIG="$HOME/Repos/ooloth/dotfiles/config"
HOMECONFIG="$HOME/.config"

source "$DOTCONFIG/zsh/banners.zsh"
info "🍱 Installing tmux terminfo updates and tpm"

############
# TERMINFO #
############

printf "💪 Installing tmux.terminfo\n"
tic -x "$DOTCONFIG/tmux/tmux.terminfo"

printf "💪 Installing xterm-256color-italic.terminfo\n"
tic -x "$DOTCONFIG/tmux/xterm-256color-italic.terminfo"

# TODO: confirm success + handle failure

#######
# TPM #
#######

TPM="$HOMECONFIG/tmux/plugins/tpm"

# Return if tpm is installed
if [ -d "$TPM" ]; then
  printf "🍱 tpm is already installed\n"
  return
fi

# Otherwise, install
printf "🍱 Installing tpm\n"

# see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
git clone "git@github.com:tmux-plugins/tpm.git" "$TPM"

printf "\n🚀 Finished installing tpm\n"