#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/tools/zsh/config/aliases.zsh"
source "${DOTFILES}/tools/zsh/utils.zsh"

info "🍺 Updating homebrew packages"

# WARN: don't include "--cleanup" flag now that some packages are installed individually instead of via brew bundle
# Install all dependencies listed in Brewfile
# see: https://github.com/Homebrew/homebrew-bundle
brew bundle --file="${DOTFILES}/tools/homebrew/config/Brewfile" # install missing packages

debug "🍺 Updating casks"
brew cu --all --include-mas --no-brew-update --yes # update casks only, including casks with their own auto-updater

debug "🚀 All Homebrew packages are up to date"
