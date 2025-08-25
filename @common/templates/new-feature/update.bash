#!/usr/bin/env bash
set -euo pipefail

# TODO: Update tool
# TODO: Install if missing
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

printf "🥁 Updating X...\n"

printf "🔗 Configuring X...\n"
source "$(dirname "${BASH_SOURCE[0]}")/symlink.bash"

printf "🎉 X is up to date\n"
