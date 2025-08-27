#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/tools/zsh/config/aliases.zsh"
source "${DOTFILES}/tools/zsh/utils.zsh"

# Install if missing
if ! have brew; then
  source "$DOTFILES/features/install/zsh/homebrew.zsh"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info "🍺 Updating homebrew"

brew update # update brew
brew autoremove # remove old versions
brew cleanup # remove junk
brew doctor || true # address any issues (but don't exit)

# Then, install and update dependencies
info "🍺 Updating homebrew packages"

# WARN: don't include "--cleanup" flag now that some packages are installed individually instead of via brew bundle
# Install all dependencies listed in Brewfile
# see: https://github.com/Homebrew/homebrew-bundle
brew bundle --file="${DOTFILES}/tools/homebrew/config/Brewfile" # install missing packages
brew upgrade --formula # update formulae only
brew cu --all --include-mas --yes # update casks only, including casks with their own auto-updater

printf "\n🚀 Homebrew and its packages are up to date\n"
