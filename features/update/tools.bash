#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

main() {
  source "${DOTFILES}/features/update/bash/mode.bash"

  # TODO: find all {features,tools}/**/update.*.bash and source them all automatically?
}

# TODO: support updating individual tools?
main "$@"
