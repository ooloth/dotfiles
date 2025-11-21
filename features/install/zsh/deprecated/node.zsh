#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"


info "🦀 Installing Node via fnm"

latest_version="$(fnm ls-remote | tail -n 1)"
installed_versions=$(fnm ls)

latest_version_is_installed() {
  echo "$installed_versions" | grep -q "$latest_version"
  return $? # Return the exit status of the grep command
}

if latest_version_is_installed; then
  printf "\n✅ The latest Node version ($latest_version) is already installed.\n"
  return_or_exit 0
fi

# Otherwise, install
fnm install "$latest_version" --corepack-enabled
fnm default "$latest_version"
fnm use "$latest_version"

printf "\n🚀 Finished installing Node $latest_version.\n"
