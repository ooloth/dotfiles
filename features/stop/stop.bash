#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")

if is_work; then
  case "${current_dir}" in
  cauldron)
    info "✋ Stopping cauldron"
    dd
    ;;

  ops-1 | ops-2)
    docker compose down -v
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
    cauldron
    dd
    genie
    dd
    pl
    dd
    skurge
    dd
    plu
    dd
    ;;

  skurge)
    dd
    ;;

  spade-flows)
    ./bin/dev/stop.sh
    ;;

  *)
    no_case_defined stop
    ;;
  esac
else
  no_case_defined stop
fi
