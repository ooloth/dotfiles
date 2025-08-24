#!/usr/bin/env bash

# TODO: Install if missing
# TODO: Otherwise, update
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

set -euo pipefail

main() {
  printf "🥁 Updating X...\n"

  # TODO: update command

  printf "🔗 Configuring X...\n"
  source "$(dirname "${BASH_SOURCE[0]}")/symlink.bash"

  printf "🎉 X is up to date\n"
}

main "$@"
