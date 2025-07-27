#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/config/zsh/aliases.zsh"
source "$DOTFILES/config/zsh/utils.zsh"
source "$DOTFILES/lib/homebrew-utils.zsh"

# Check if Homebrew is already installed
if detect_homebrew; then
  return_or_exit 0
fi

# Otherwise, install
info "🍺 Installing homebrew"

# See: https://brew.sh
# Run as a login shell (non-interactive) so that the script doesn't pause for user input
# Use "arch -arm64" to ensure Apple Silicon version installed: https://github.com/orgs/Homebrew/discussions/417#discussioncomment-2684303
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | arch -arm64 /bin/bash --login

eval "$(/opt/homebrew/bin/brew shellenv)"

printf "\n🚀 Finished installing $(brew --version).\n"
