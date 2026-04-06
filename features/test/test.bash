#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

args=""
current_dir=$(basename "${PWD}")
error_msg="🚨 No 'test' case defined for '/${current_dir}'"

if [ "$#" -gt 0 ]; then
  args=" ${*}"
fi

case $current_dir in
agency-1 | agency-2)
  uv run --frozen pytest
  exit 0
  ;;

agent-1 | agent-2)
  uv run --frozen pytest
  ;;
esac

if is_work; then
  case "${current_dir}" in
  ops-1 | ops-2 | ops-3)
    uv run pytest
    ;;

  mapapp-1 | mapapp-2 | mapapp-3)
    ./bin/test.sh "$@"
    ;;

  react-app)
    info "🧪 Running: vitest$args"
    npm run test "$@"
    ;;

  spade-flows)
    ./bin/dev/test.sh "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
else
  case "${current_dir}" in
  advent-of-code)
    ./bin/test "$@"
    ;;

  hub)
    PYTHONPATH=. pytest "$@"
    ;;

  michaeluloth.com)
    npm run test "$@"
    ;;

  scripts)
    PYTHONPATH=. pytest "$@"
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
fi
