u() {
  source "$DOTFILES/bin/update/mode.zsh"
  source "$DOTFILES/bin/update/symlinks.zsh"
  source "$DOTFILES/bin/update/rust.zsh"

  info "✨ Updating yazi dependencies"
  git -C "$HOME/Repos/yazi-rs/flavors" pull;

  source "$DOTFILES/bin/update/neovim.zsh"
  source "$DOTFILES/bin/update/tpm.zsh"
  source "$DOTFILES/bin/update/npm.zsh"
  source "$DOTFILES/bin/update/gcloud.zsh"
  source "$DOTFILES/bin/update/homebrew.zsh"
  source "$DOTFILES/bin/update/macos.zsh"

  info "🔄 Reloading shell"
  R
}