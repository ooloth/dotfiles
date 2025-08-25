#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${HOME}/Repos/ooloth/dotfiles"

# Find all update.bash files
update_files=$(find "${DOTFILES}/tools" -type f -name "update.*.bash")

# Iterate over the files and execute them
for file in $update_files; do
  printf "🔄 Running %s\n" "$file"
  bash "$file"
done
