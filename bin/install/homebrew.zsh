#!/usr/bin/env zsh

# Return if installed
if have brew; then
  printf "\n🍺 Homebrew is already installed\n"
  return
fi

# Otherwise, install
source "$HOME/Repos/ooloth/dotfiles/config/zsh/utils.zsh"
info "🍺 Installing homebrew"

# See: https://brew.sh
# Run as a login shell (non-interactive) so that the script doesn't pause for user input
# Use "arch -arm64" to ensure Apple Silicon version installed: https://github.com/orgs/Homebrew/discussions/417#discussioncomment-2684303
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | arch -arm64 /bin/bash --login

eval "$(/opt/homebrew/bin/brew shellenv)"

printf "\n🚀 Finished installing $(brew --version).\n"
