#!/usr/bin/env zsh
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/zsh/utils.zsh"

main() {
  source "${DOTFILES}/features/update/zsh/rust.zsh"
  source "${DOTFILES}/features/update/zsh/neovim.zsh"
  source "${DOTFILES}/features/update/zsh/tmux.zsh"
  source "${DOTFILES}/features/update/zsh/npm.zsh"
  source "${DOTFILES}/features/update/zsh/gcloud.zsh"
  source "${DOTFILES}/features/update/zsh/homebrew.zsh"
  source "${DOTFILES}/features/update/zsh/macos.zsh"

  info "🐚 Reloading zsh"
  exec -l "${SHELL}"
}

# TODO: support updating individual tools?
main "$@"
