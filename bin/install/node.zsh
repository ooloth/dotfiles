#!/usr/bin/env zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🦀 Installing Node via fnm"

latest_version="$(fnm ls-remote | tail -n 1)"
installed_versions=$(fnm ls)

latest_version_is_installed() {
  echo "$installed_versions" | grep -q "$latest_version"
}

# Return if installed
if latest_version_is_installed; then
  printf "\n✅ The latest Node version ($latest_version) is already installed.\n"
  return
fi

# Otherwise, install
fnm install "$latest_version" --corepack-enabled
fnm default "$latest_version"
fnm use "$latest_version"

printf "\n🚀 Finished installing Node $latest_version.\n"