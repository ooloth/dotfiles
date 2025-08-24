#!/usr/bin/env bash

# TODO: Skip if already found and up to date
# TODO: Install otherwise
# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

set -euo pipefail

main() {
  printf "🥁 Installing X...\n"

  # TODO: install command

  printf "🔗 Configuring X...\n"
  source "$(dirname "${BASH_SOURCE[0]}")/symlink.bash"

  printf "🎉 X is installed and configured\n"
}

main "$@"
