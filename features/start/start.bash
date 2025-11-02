#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'start' case defined for '/${current_dir}'"

if is_work; then
  case "${current_dir}" in
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
    error "${error_msg}"
    ;;
  esac
else
  error "${error_msg}"
fi
