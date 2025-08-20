#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🥁 Updating X...\n"

  # TODO: Install if missing
  # TODO: Otherwise, update
  # TODO: Validate update (e.g. command is available, version is correct)
  # TODO: Symlink configuration files (overkill? might as well?)
  # TODO: Validate configuration (e.g. options are still valid)

  printf "🎉 X is up to date\n"
}

main "$@"
