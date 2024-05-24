#!/usr/bin/env zsh

# Return early if not installed
if ! command -v gcloud &> /dev/null; then
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "✨ Updating gcloud components"

# The "quiet" flag skips interactive prompts by using the default or erroring (see: https://stackoverflow.com/a/31811541/8802485)
gcloud components update --quiet