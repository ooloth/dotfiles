#!/usr/bin/env zsh

TPM="$HOME/.config/tmux/plugins/tpm"
DOTFILES="$HOME/Repos/ooloth/dotfiles"

# Install if missing
if [ ! -d "$TPM" ]; then
  source "$DOTFILES/features/install/zsh/tmux.zsh"
fi

# Then, update
source "$DOTFILES/tools/zsh/utils.zsh"
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
