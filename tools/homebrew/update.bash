#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🍺 Updating homebrew"

debug "📦 Regenerating combined Brewfile"
bash "${DOTFILES}/tools/homebrew/generate-brewfile.bash"

debug "🍺 Refreshing formula database"
brew update

debug "📦 Ensuring all declared packages are installed"
brew bundle --file="${DOTFILES}/tools/homebrew/config/Brewfile.generated"

debug "📦 Upgrading all installed packages"
brew upgrade

debug "📦 Updating casks"
brew cu --all --include-mas --no-brew-update --yes --cleanup

debug "🚀 All Homebrew packages are up to date"

debug "🍺 Removing orphaned subdependencies"
brew autoremove

debug "🍺 Removing old downloads"
brew cleanup --quiet
