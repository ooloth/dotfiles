#!/usr/bin/env bash

# TODO: Delete configuration file symlinks (NOT the dotfiles copy)
# TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

# See: https://harlequin.sh/docs/getting-started/index

set -euo pipefail

main() {
  printf "🗑️ Uninstalling harlequin...\n"

  uv tool uninstall harlequin

  printf "🎉 harlequin has been uninstalled\n"
}

main "$@"
