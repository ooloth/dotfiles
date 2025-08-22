#!/usr/bin/env bash

# TODO: Skip if no longer present
# TODO: Delete configuration file symlinks (NOT the dotfiles)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

set -euo pipefail

main() {
  printf "🗑️ Uninstalling X...\n"

  # TODO: uninstall commands

  printf "🎉 X has been uninstalled\n"
}

main "$@"
