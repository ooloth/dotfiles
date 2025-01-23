#!/usr/bin/env zsh

DOTCONFIG="$HOME/Repos/ooloth/dotfiles/config"
HOMECONFIG="$HOME/.config"

source "$DOTCONFIG/zsh/utils.zsh"
info "🍱 Installing tpm and tmux plugins"
# info "🍱 Installing tmux terminfo updates and tpm plugins"

############
# TERMINFO #
############

# TODO: still needed? going to try skipping...

# printf "💪 Installing tmux.terminfo\n"
# tic -x "$DOTCONFIG/tmux/tmux.terminfo"

# printf "💪 Installing xterm-256color-italic.terminfo\n"
# tic -x "$DOTCONFIG/tmux/xterm-256color-italic.terminfo"

# TODO: confirm success + handle failure

#######
# TPM #
#######

TPM="$HOMECONFIG/tmux/plugins/tpm"

if [ -d "$TPM" ]; then
  printf "🍱 tpm is already installed\n"
else
  printf "🍱 Installing tpm\n"

  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  git clone "git@github.com:tmux-plugins/tpm.git" "$TPM"
fi

###############
# TPM PLUGINS #
###############

printf "🍱 Installing tpm plugins\n"

"$TPM/bin/install_plugins"

printf "\n🚀 Finished installing tmux\n"
