#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🔗 Symlinking X configuration files...\n"

  # TODO: Install if missing
  # TODO: Otherwise, install
  # TODO: Validate installation (e.g. command is available, version is correct)
  # TODO: Symlink configuration files
  # TODO: Validate configuration

  printf "🎉 X configuration files are symlinked\n"
}

main "$@"
