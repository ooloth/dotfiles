#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

export HOMEBREW_NO_INSTALL_CLEANUP=1  # don't auto-remove old versions after every install/upgrade

if have brew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
