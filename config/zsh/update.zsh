u() {
  source "$DOTFILES/bin/update/mode.zsh"
  source "$DOTFILES/bin/update/symlinks.zsh"
  source "$DOTFILES/bin/update/rust.zsh"
  source "$DOTFILES/bin/update/yazi.zsh"
  source "$DOTFILES/bin/update/neovim.zsh"
  source "$DOTFILES/bin/update/tmux.zsh"
  source "$DOTFILES/bin/update/npm.zsh"
  source "$DOTFILES/bin/update/gcloud.zsh"
  source "$DOTFILES/bin/update/homebrew.zsh"
  source "$DOTFILES/bin/update/macos.zsh"

  info "🐚 Reloading shell"
  exec -l $SHELL
}