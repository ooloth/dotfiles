#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

if is_work; then
  case "${current_dir}" in
  cauldron)
    du
    ;;

  ops-1 | ops-2)
    info "🚀 Starting database + API"
    docker compose up --build --detach
    uvicorn rxrx.valid.clinical_ingest.app:app --reload
    ;;

  genie)
    # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
    du
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

  mapapp-4)
    ./bin/dev.sh
    ;;

  platelet)
    # see: https://github.com/recursionpharma/platelet/blob/trunk/docs/setup/index.md
    GOOGLE_CLOUD_PROJECT=eng-infrastructure du
    ;;

  platelet-ui)
    info "🚀 Starting cauldron, genie, skurge, platelet and platelet-ui"
    cauldron
    du
    genie
    du
    pl
    du
    skurge
    du
    plu
    n
    du
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
    no_case_defined start
    ;;
  esac
else
  case "${current_dir}" in
  michaeluloth.com)
    npm run dev
    ;;

  *)
    no_case_defined start
    ;;
  esac
fi
