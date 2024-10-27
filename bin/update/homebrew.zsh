#!/usr/bin/env zsh

# Install if missing
if ! have brew; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/homebrew.zsh"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Then, install and update dependencies
DOTFILES="$HOME/Repos/ooloth/dotfiles"
source "$DOTFILES/config/zsh/banners.zsh"
info "🍺 Updating homebrew packages"

# Install all dependencies listed in Brewfile (and remove any that aren't)
# see: https://github.com/Homebrew/homebrew-bundle
brew bundle --file="$DOTFILES/macos/Brewfile" --cleanup

brew update # update brew
brew upgrade # update packages
brew cu # update casks
brew autoremove # remove old versions
brew cleanup # remove junk
brew doctor # address any issues
