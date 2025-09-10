#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "💎 Installing Ruby"

printf "📦 Installing ruby dependencies\n"
brew bundle --file="${DOTFILES}/tools/ruby/Brewfile"

if ! have mise; then
  source "${DOTFILES}/tools/mise/install.bash"
fi

if ! have rustc; then
  # Prefer native installer over brew installation recommended by ruby on rails
  source "${DOTFILES}/tools/rust/install.bash"
fi

debug "💎 Installing ruby via mise"
# See: https://guides.rubyonrails.org/install_ruby_on_rails.html#install-ruby-on-macos
mise use -g ruby@3
