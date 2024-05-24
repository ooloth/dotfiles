#!/usr/bin/env zsh

# Install if missing
if ! command -v brew &> /dev/null; then
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

# Update brew, upgrade outdated packages, remove old versions and address any issues
brew update && brew upgrade && brew autoremove && brew cleanup && brew doctor