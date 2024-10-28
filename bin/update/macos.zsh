#!/usr/bin/env zsh

# Return early on work laptop to avoid issues caused by updating too early
if $IS_WORK; then
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/utils.zsh"
info "💻 Updating macOS software (after password, don't cancel!)"

sudo softwareupdate --install --all --restart --agree-to-license --verbose
