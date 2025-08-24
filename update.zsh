#!/usr/bin/env zsh

set -euo pipefail

source "${DOTFILES}/zsh/config/utils.zsh"

main() {
  source "${DOTFILES}/bin/update/mode.zsh"
  source "${DOTFILES}/bin/update/symlinks.zsh"
  source "${DOTFILES}/bin/update/rust.zsh"
  source "${DOTFILES}/bin/update/uv.zsh"
  source "${DOTFILES}/bin/update/neovim.zsh"
  source "${DOTFILES}/bin/update/tmux.zsh"
  source "${DOTFILES}/bin/update/npm.zsh"
  source "${DOTFILES}/bin/update/gcloud.zsh"
  source "${DOTFILES}/bin/update/homebrew.zsh"
  source "${DOTFILES}/bin/update/macos.zsh"

  info "🐚 Reloading zsh"
  exec -l "${SHELL}"
}

# TODO: support updating specific features?
main "$@"
