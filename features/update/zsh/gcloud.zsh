#!/usr/bin/env zsh

main() {
  # Return early if not installed
  if ! have gcloud; then
    return 0
  fi

  # Otherwise, update
  source "$DOTFILES/tools/zsh/utils.zsh"
  info "✨ Updating gcloud components"

  # The "quiet" flag skips interactive prompts by using the default or erroring (see: https://stackoverflow.com/a/31811541/8802485)
  gcloud components update --quiet

  printf "🎉 All gcloud components are up to date\n"
}

main "$@"
