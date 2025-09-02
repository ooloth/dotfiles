#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/tools/zsh/config/aliases.zsh"
source "${DOTFILES}/tools/zsh/utils.zsh"

info "🍺 Updating homebrew packages"

# Install all dependencies listed in Brewfile
# see: https://github.com/Homebrew/homebrew-bundle
brew bundle --file="${DOTFILES}/tools/homebrew/config/Brewfile" # ensure installed + updated (no --cleanup flag! some packages are installed individually now)

debug "🍺 Updating casks"
brew cu --all --include-mas --no-brew-update --yes # update casks only, including casks with their own auto-updater

debug "🚀 All Homebrew packages are up to date"
