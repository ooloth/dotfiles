#!/usr/bin/env bash
set -euo pipefail

restart() {
  local CURRENT_DIRECTORY=$(basename "${PWD}")

  case $CURRENT_DIRECTORY in
  *)
    error "🚨 No 'restart' case defined for '/${CURRENT_DIRECTORY}'"
    ;;
  esac

  if is_work; then
    case $CURRENT_DIRECTORY in
    spade-flows)
      ./bin/dev/restart.sh "$@"
      ;;

    *)
      error "🚨 No 'restart' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
    esac
  fi
}
