#!/usr/bin/env bash
set -euo pipefail

start() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
  *)
    error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}'"
    ;;
  esac

  if is_work; then
    case $CURRENT_DIRECTORY in
    cauldron)
      du
      ;;

    genie)
      # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
      du
      ;;

    grey-havens)
      ./run-local.sh
      ;;

    mapapp-1)
      ./bin/dev.sh
      ;;

    mapapp-2)
      ./bin/dev.sh
      ;;

    mapapp-3)
      ./bin/dev.sh
      ;;

    platelet)
      # see: https://github.com/recursionpharma/platelet/blob/trunk/docs/setup/index.md
      GOOGLE_CLOUD_PROJECT=eng-infrastructure du
      ;;

    platelet-ui)
      info "🚀 Starting cauldron, genie, skurge, platelet and platelet-ui"
      cauldron && dud
      genie && dud
      pl && dud
      skurge && dud
      plu && n && du
      ;;

    processing-witch)
      python -m main
      ;;

    react-app)
      info "🚀 Starting vite server"
      npm install
      npm start
      ;;

    skurge)
      du
      ;;

    spade-flows)
      ./bin/dev/start.sh
      ;;

    tech)
      ns
      ;;

    *)
      error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
    esac
  fi
}
