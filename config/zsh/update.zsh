u() {
  info "🔗 Updating symlinks"
  $DOTFILES/bin/create-symlinks.zsh

  info "✨ Updating rust dependencies"
  rustup update

  info "✨ Updating tmux dependencies"
  # see: https://github.com/tmux-plugins/tpm/blob/master/docs/managing_plugins_via_cmd_line.md
  ~/.config/tmux/plugins/tpm/bin/clean_plugins
  ~/.config/tmux/plugins/tpm/bin/install_plugins
  ~/.config/tmux/plugins/tpm/bin/update_plugins all

  info "✨ Updating neovim dependencies"
  git -C $HOME/Repos/knubie/vim-kitty-navigator pull;

  # TODO: update lazy.nvim plugins here as well? in all nvim instances? pin dependencies to avoid unwanted updates?

  # see: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
  info "✨ Updating Node $(node -v) global dependencies"
  # TODO: only if out of date (to avoid wasting time?)
	ng

  if $IS_WORK_LAPTOP; then
    info "✨ Updating gcloud components"
    # The "quiet" flag skips interactive prompts by using the default or erroring (see: https://stackoverflow.com/a/31811541/8802485)
    gcloud components update --quiet
  fi

  info "✨ Installing VS Code extensions"
  # TODO: replace with Brewfile
  cat "$DOTFILES/vscode/extensions.txt" | xargs -L 1 code --install-extension

  info "✨ Updating brew packages"
  # Install missing packages, upgrade outdated packages, and remove old versions
  # TODO: maintain separate Brewfiles for work laptop, personal laptop and Mini?
  # Ok to vary the file name?
  # If not, can I symlink the Brewfile to the appropriate one based on the $HOSTNAME?
  # Reference the appropriate one by interpolating the $HOSTNAME?
  brew bundle --file=$DOTFILES/macos/Brewfile
	brew update && brew upgrade && brew autoremove && brew cleanup && brew doctor

  # Avoid potential issues on work laptop caused by updating macOS too early
  if ! $IS_WORK_LAPTOP; then
    info "💻 Updating macOS software (don't cancel!)"
    sudo softwareupdate --install --all --restart --agree-to-license --verbose
  fi

  info "🔄 Reloading shell"
  R
}