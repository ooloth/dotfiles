#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🗑️ Uninstalling visidata...\n"

  # TODO: Uninstall if present

  uv tool uninstall visidata

  # TODO: Delete configuration file symlinks (NOT the dotfiles)
  # TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

  printf "🎉 visidata has been uninstalled\n"
}

main "$@"
