#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

if have brew; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
