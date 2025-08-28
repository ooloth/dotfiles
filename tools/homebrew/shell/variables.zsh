#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1      # I'll update manually (don't slow down individual install/upgrade commands)
export HOMEBREW_NO_INSTALL_CLEANUP=1  # I'll clean up manually (don't slow down individual install/upgrade commands)

if have brew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
