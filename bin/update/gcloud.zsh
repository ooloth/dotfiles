#!/usr/bin/env zsh


# Return early if not installed
if ! have gcloud; then
  source "$DOTFILES/config/zsh/aliases.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/config/zsh/utils.zsh"
info "✨ Updating gcloud components"

# The "quiet" flag skips interactive prompts by using the default or erroring (see: https://stackoverflow.com/a/31811541/8802485)
gcloud components update --quiet
