#!/usr/bin/env zsh
set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.zsh"

main() {
  source "${DOTFILES}/features/symlink/link.zsh"
  source "${DOTFILES}/features/update/zsh/rust.zsh"
  source "${DOTFILES}/features/update/zsh/uv.zsh"
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
