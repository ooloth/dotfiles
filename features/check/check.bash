#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'check' case defined for '/${current_dir}'"

if is_work; then
  case $current_dir in
  mapapp-1 | mapapp-2 | mapapp-3)
    ./bin/check.sh "$@"
    ;;

  react-app)
    info "Formatting, linting and type-checking"
    npm run lint
    ;;

  spade-flows)
    ./bin/dev/check.sh "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
else
  error "${error_msg}"
fi
