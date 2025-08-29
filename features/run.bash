#!/usr/bin/env bash
set -euo pipefail

run() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
  advent-of-code)
    ./bin/run "$@"
    ;;

  *)
    error "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}'"
    ;;
  esac

  if is_work; then
    case $CURRENT_DIRECTORY in
    spade-flows)
      ./bin/dev/run.sh "$@"
      ;;

    *)
      error "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
    esac
  fi
}
