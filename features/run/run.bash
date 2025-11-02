#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'run' case defined for '/${current_dir}'"

if is_work; then
  case "${current_dir}" in
  spade-flows)
    ./bin/dev/run.sh "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
else
  case "${current_dir}" in
  advent-of-code)
    ./bin/run "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
fi
