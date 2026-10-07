#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

if is_work; then
  case "${current_dir}" in
  spade-flows)
    ./bin/dev/restart.sh "$@"
    ;;

  *)
    no_case_defined restart
    ;;
  esac
else
  no_case_defined restart
fi
