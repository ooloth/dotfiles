#!/usr/bin/env bash
set -euo pipefail

stop() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
  *)
    error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}'"
    ;;
  esac

  if is_work; then
    case $CURRENT_DIRECTORY in
    cauldron)
      info "✋ Stopping cauldron"
      dd
      ;;

    genie)
      info "✋ Stopping genie"
      dd
      ;;

    mapapp-1)
      info "✋ Stopping observability stack"
      dd
      ;;

    mapapp-2)
      info "✋ Stopping observability stack"
      dd
      ;;

    mapapp-3)
      info "✋ Stopping observability stack"
      dd
      ;;

    platelet-ui)
      info "✋ Stopping cauldron, genie, skurge, platelet and platelet-ui"
      cauldron && dd
      genie && dd
      pl && dd
      skurge && dd
      plu && dd
      ;;

    skurge)
      dd
      ;;

    spade-flows)
      ./bin/dev/stop.sh
      ;;

    *)
      error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
    esac
  fi
}
