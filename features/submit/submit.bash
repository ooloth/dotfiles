#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

case "${current_dir}" in
advent-of-code)
  bin/submit "$@"
  ;;
*)
  no_case_defined submit
  ;;
esac
