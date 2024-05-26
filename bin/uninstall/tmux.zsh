#!/usr/bin/env zsh

# NOTE: this reverses the changes made by bin/install/tmux.zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🍱 Uninstalling terminfo updates and tpm plugins"

############
# TERMINFO #
############

printf "🗑️ Uninstalling tmux.terminfo\n"
infocmp tmux-256color | tic -x -

printf "🗑️ Uninstalling xterm-256color-italic.terminfo\n"
infocmp xterm-256color-italic | tic -x -

# TODO: confirm success + handle failure

#######
# TPM #
#######

TPM_DIR="$HOME/.config/tmux/plugins"

# Return if tpm is not installed
if [ ! -d "$TPM_DIR" ]; then
  printf "🍱 tpm and its plugins are not installed\n"
else
  printf "🍱 Uninstalling tpm and its plugins\n"
  rm -rf "$TPM_DIR"
fi

printf "\n🚀 Finished uninstalling tmux\n"