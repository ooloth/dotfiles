#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'check' case defined for '/${current_dir}'"

case $current_dir in
agency-1 | agency-2)
  uv run --frozen prek run --all-files
  exit 0
  ;;

agent-1 | agent-2)
  uv run --frozen prek run --all-files
  exit 0
  ;;
esac

if is_work; then
  case $current_dir in
  ops-1 | ops-2 | ops-3)
    uv run prek run --all-files
    ;;

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
  case $current_dir in
  media-tools)
    uv run prek run --all-files
    exit 0
    ;;

  michaeluloth.com)
    npm run format "$@"
    npm run lint "$@"
    npm run typecheck "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
fi
