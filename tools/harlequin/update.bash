#!/usr/bin/env bash

# TODO: Skip if found
# TODO: Otherwise, update
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

set -euo pipefail

main() {
  printf "🥁 Updating harlequin...\n"

  uv tool upgrade harlequin

  printf "🎉 harlequin is up to date\n"
}

main "$@"
