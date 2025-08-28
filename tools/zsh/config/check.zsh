#!/usr/bin/env zsh

check() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac

  if is_work; then
    case $CURRENT_DIRECTORY in
      mapapp)
        ./bin/check.sh "$@" ;;

      mapapp-1)
        ./bin/check.sh "$@" ;;

      mapapp-2)
        ./bin/check.sh "$@" ;;

      mapapp-3)
        ./bin/check.sh "$@" ;;

      react-app)
        info "Formatting, linting and type-checking"
        npm run lint ;;

      spade-flows)
        ./bin/dev/check.sh "$@" ;;

      *)
        error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
    esac
  fi
}

