#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/zsh/config/aliases.zsh"
source "$DOTFILES/zsh/config/utils.zsh"

# Install if missing
if ! have brew; then
  source "$DOTFILES/bin/install/homebrew.zsh"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Then, install and update dependencies
info "🍺 Updating homebrew packages"

# Install all dependencies listed in Brewfile (and remove any that aren't)
# see: https://github.com/Homebrew/homebrew-bundle
brew bundle --file="$DOTFILES/homebrew/config/Brewfile" --cleanup

brew update # update brew
brew upgrade # update packages
brew cu # update casks
brew autoremove # remove old versions
brew cleanup # remove junk
brew doctor # address any issues

printf "🎉 All homebrew packages are up to date\n"
