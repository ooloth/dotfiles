#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🥁 Installing X...\n"

  # TODO: Install if missing
  # TODO: Otherwise, install
  # TODO: Validate installation (e.g. command is available, version is correct)
  # TODO: Symlink configuration files
  # TODO: Validate configuration

  printf "🎉 X is installed and configured\n"
}

main "$@"
