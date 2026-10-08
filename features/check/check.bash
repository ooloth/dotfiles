#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

# Projects shared across machines come first, so a match here never reaches the machine cases
case $current_dir in
agency-1 | agency-2)
  uv run --frozen prek run --all-files
  ;;

agent-1 | agent-2)
  uv run --frozen prek run --all-files
  ;;

*)
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
      no_case_defined check
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
      no_case_defined check
      ;;
    esac
  fi
  ;;
esac
