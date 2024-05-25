u() {
  source "$DOTFILES/bin/update/mode.zsh"
  source "$DOTFILES/bin/update/symlinks.zsh"
  source "$DOTFILES/bin/update/rust.zsh"

  info "✨ Updating yazi dependencies"
  git -C "$HOME/Repos/yazi-rs/flavors" pull;

  info "✨ Updating neovim dependencies"
  git -C "$HOME/Repos/knubie/vim-kitty-navigator" pull;

  # TODO: update lazy.nvim plugins here as well? in all nvim instances? pin dependencies to avoid unwanted updates?

  source "$DOTFILES/bin/update/tpm.zsh"
  source "$DOTFILES/bin/update/npm.zsh"
  source "$DOTFILES/bin/update/gcloud.zsh"
  source "$DOTFILES/bin/update/homebrew.zsh"
  source "$DOTFILES/bin/update/macos.zsh"

  info "🔄 Reloading shell"
  R
}