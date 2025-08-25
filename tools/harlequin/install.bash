#!/usr/bin/env bash

# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

# See: https://harlequin.sh/docs/getting-started/index

set -euo pipefail

main() {
  printf "🥁 Installing harlequin...\n"

  uv tool install harlequin

  printf "🎉 harleuin is installed and configured\n"
}

main "$@"
