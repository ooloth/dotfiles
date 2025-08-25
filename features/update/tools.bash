#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

main() {
  source "${DOTFILES}/features/update/bash/mode.bash"

  # Find all update.bash files
  update_files=$(find "${DOTFILES}/tools" -type f -name "update.bash")

  # TODO: find all {features,tools}/**/update.*.bash and source them all automatically?
  # Iterate over the files and execute them
  for file in $install_files; do
    printf "🔄 Running %s\n" "$file"
    printf "Careful! Enable actual command only if you're sure.\n"
    # bash "$file"
  done
}

# TODO: support updating individual tools?
main "$@"
