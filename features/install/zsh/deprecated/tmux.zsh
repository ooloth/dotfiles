#!/usr/bin/env zsh

TPM="$HOME/.config/tmux/plugins/tpm"
DOTFILES="$HOME/Repos/ooloth/dotfiles"

###########
# INSTALL #
###########

info "🍱 Installing tpm and tmux plugins"

if [ -d "$TPM" ]; then
  printf "🍱 tpm is already installed\n"
else
  printf "🍱 Installing tpm\n"

  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  git clone "git@github.com:tmux-plugins/tpm.git" "$TPM"
fi

##########
# UPDATE #
##########

info "✨ Updating tmux dependencies"

# see: https://github.com/tmux-plugins/tpm/blob/master/docs/managing_plugins_via_cmd_line.md
"$TPM/bin/clean_plugins"
"$TPM/bin/install_plugins"
"$TPM/bin/update_plugins" all

# Reload tmux config automatically if it's running
if pgrep -q tmux; then
  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  printf "\n🔁 Reloading tmux config\n"
  tmux source ~/.config/tmux/tmux.conf
fi

printf "\n🎉 All tpm plugins are up to date\n"
