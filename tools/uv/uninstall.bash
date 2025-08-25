#!/usr/bin/env bash

# See: https://docs.astral.sh/uv/getting-started/installation/#uninstallation

set -euo pipefail

export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

main() {
  printf "🐍 Uninstalling uv...\n"

  # TODO: Uninstall if present

  printf "Cleaning uv cache and other stored data...\n"
  uv cache clean
  rm -r "$(uv python dir)"
  rm -r "$(uv tool dir)"

  printf "Uninstalling the uv and uvx binaries...\n"
  rm ~/.local/bin/uv ~/.local/bin/uvx

  # TODO: Delete configuration file symlinks (NOT the dotfiles)
  # TODO: Validate uninstallation (e.g. command is unavailable, symlinks are gone)

  printf "🎉 uv has been uninstalled\n"
}

main "$@"
