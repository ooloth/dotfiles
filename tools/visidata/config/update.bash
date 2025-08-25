#!/usr/bin/env bash

# TODO: Skip installation if found
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

set -euo pipefail

main() {
  printf "🥁 Updating visidata...\n"

  uv tool upgrade visidata

  printf "🎉 visidata is up to date\n"
}

main "$@"
