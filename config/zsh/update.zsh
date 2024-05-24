u() {
  source "$DOTFILES/bin/update/mode.zsh"
  source "$DOTFILES/bin/update/symlinks.zsh"
  source "$DOTFILES/bin/update/rust.zsh"

  info "✨ Updating yazi dependencies"
  git -C "$HOME/Repos/yazi-rs/flavors" pull;

  info "✨ Updating neovim dependencies"
  git -C "$HOME/Repos/knubie/vim-kitty-navigator" pull;

  # TODO: update lazy.nvim plugins here as well? in all nvim instances? pin dependencies to avoid unwanted updates?

  # If tpm is installed, update its dependencies
  if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
    info "✨ Updating tmux dependencies"
    # see: https://github.com/tmux-plugins/tpm/blob/master/docs/managing_plugins_via_cmd_line.md
    ~/.config/tmux/plugins/tpm/bin/clean_plugins
    ~/.config/tmux/plugins/tpm/bin/install_plugins
    ~/.config/tmux/plugins/tpm/bin/update_plugins all
  fi

  source "$DOTFILES/bin/update/npm.zsh"
  source "$DOTFILES/bin/update/gcloud.zsh"
  source "$DOTFILES/bin/update/homebrew.zsh"
  source "$DOTFILES/bin/update/macos.zsh"

  info "🔄 Reloading shell"
  R
}