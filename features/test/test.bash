#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

args=""
current_dir=$(basename "${PWD}")

if [ "$#" -gt 0 ]; then
  args=" ${*}"
fi

# Projects shared across machines come first, so a match never reaches a machine's no-match branch
case $current_dir in
agency-1 | agency-2)
  uv run --frozen pytest
  ;;

agent-1 | agent-2)
  uv run --frozen pytest
  ;;

*)
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
      no_case_defined test
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

    media-tools)
      uv run pytest "$@"
      ;;

    michaeluloth.com)
      npm run test "$@"
      ;;

    scripts)
      PYTHONPATH=. pytest "$@"
      ;;

    *)
      no_case_defined test
      ;;
    esac
  fi
  ;;
esac
