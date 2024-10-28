#!/usr/bin/env zsh


# Return early on work laptop to avoid issues caused by updating too early
if $IS_WORK; then
  source "$DOTFILES/config/zsh/aliases.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/config/zsh/utils.zsh"
info "💻 Updating macOS software (after password, don't cancel!)"

sudo softwareupdate --install --all --restart --agree-to-license --verbose
