#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'restart' case defined for '/${current_dir}'"

if is_work; then
  case "${current_dir}" in
  spade-flows)
    ./bin/dev/restart.sh "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
else
  error "${error_msg}"
fi
