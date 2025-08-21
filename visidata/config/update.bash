#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🥁 Updating visidata...\n"

  # TODO: Install if missing

  # Otherwise, update
  uv tool upgrade visidata

  # TODO: Validate update (e.g. command is available, version is correct)
  # TODO: Symlink configuration files (overkill? might as well?)
  # TODO: Validate configuration (e.g. options are still valid)

  printf "🎉 visidata is up to date\n"
}

main "$@"
