#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

if have zoxide; then
  eval "$(zoxide init zsh)"
fi
