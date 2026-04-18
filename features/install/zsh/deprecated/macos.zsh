#!/usr/bin/env zsh


# Return early on work laptop to avoid issues caused by updating too early
if is_work; then
  return_or_exit 0
fi

# Otherwise, update
info "💻 Updating macOS software (after password, don't cancel!)"

sudo softwareupdate --install --all --restart --agree-to-license --verbose

printf "🎉 All macOS software is up to date\n"
