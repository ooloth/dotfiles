#!/usr/bin/env bash

# TODO: {feature}/install.bash and {feature}/update.bash should both source this file
# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

set -euo pipefail

main() {
  printf "🔗 Symlinking X configuration files...\n"

  # TODO: Install if missing

  printf "🎉 X configuration files are symlinked\n"
}

main "$@"
