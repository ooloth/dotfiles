#!/usr/bin/env bash
set -euo pipefail

check() {
  local current_dir=$(basename "${PWD}")
  local error_msg="🚨 No 'check' case defined for '/${current_dir}'"

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
}
