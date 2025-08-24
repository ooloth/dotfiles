#!/usr/bin/env bash

# TODO: {feature}/install.bash and {feature}/update.bash should both source this file

set -euo pipefail

main() {
  printf "🔗 Symlinking X configuration files...\n"

  # TODO: Install if missing
  # TODO: Validate installation (e.g. command is available, version is correct)
  # TODO: Symlink configuration files
  # TODO: Validate configuration

  printf "🎉 X configuration files are symlinked\n"
}

main "$@"
