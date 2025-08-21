#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🥁 Installing visidata as a uv tool...\n"

  # TODO: Install if missing
  # TODO: Validate installation (e.g. command is available, version is correct)
  # TODO: Symlink configuration files
  # TODO: Validate configuration

  uv tool install visidata

  printf "🎉 visidata is installed and configured\n"
}

main "$@"
