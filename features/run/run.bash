#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

if is_work; then
  case "${current_dir}" in
  spade-flows)
    ./bin/dev/run.sh "$@"
    ;;

  *)
    no_case_defined run
    ;;
  esac
else
  case "${current_dir}" in
  advent-of-code)
    ./bin/run "$@"
    ;;

  *)
    no_case_defined run
    ;;
  esac
fi
