#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash" # source last to avoid env var overrides

info "🍺 Updating homebrew"
brew update

debug "📦 Updating homebrew packages"
readarray -t homebrew_leaves < <(brew leaves -r)
brew upgrade --formulae "${homebrew_leaves[@]}"

# Install all dependencies listed in Brewfile
# see: https://github.com/Homebrew/homebrew-bundle
# brew bundle --file="${DOTFILES}/tools/homebrew/config/Brewfile" # ensure installed + updated (no --cleanup flag! some packages are installed individually now)

debug "📦 Updating casks"
brew cu --all --include-mas --no-brew-update --yes --cleanup

debug "🚀 All Homebrew packages are up to date"

debug "${TOOL_EMOJI} Caching updated list of outdated formulae"
cache_brew_outdated_formula_list

debug "${TOOL_EMOJI} Removing orphaned subdependencies\n"
brew autoremove

debug "${TOOL_EMOJI} Removing old downloads\n"
brew cleanup --quiet
