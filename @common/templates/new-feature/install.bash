#!/usr/bin/env bash
set -euo pipefail

# TODO: Install command
# TODO: Skip if already found and up to date
# TODO: Validate installation (e.g. command is available, version is correct)
# TODO: Symlink configuration files
# TODO: Validate configuration

printf "🥁 Installing X...\n"

printf "🔗 Configuring X...\n"
source "$(dirname "${BASH_SOURCE[0]}")/symlink.bash"

printf "🎉 X is installed and configured\n"
