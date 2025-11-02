#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'new' case defined for '/${current_dir}'"

case "${current_dir}" in
advent-of-code)
  ./bin/new "$@"
  ;;

*)
  error "${error_msg}"
  ;;
esac
