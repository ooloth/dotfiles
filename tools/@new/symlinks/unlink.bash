#!/usr/bin/env bash
set -euo pipefail

printf "🔗 Removing symlinked X config files...\n"
# TODO: confirm this removes the whole directory safely (not just the symlink)
# rm -r "${HOME}/.config/X"
