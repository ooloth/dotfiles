stop() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    bc-lowe)
      info "✋ Stopping postgres instance running on port 5432"
      kubectl delete -f deploy/local/postgres.yaml
      lsof -t -i:5432 | xargs kill -9

      info "✋ Stopping redis instance running on port 6379"
      kubectl delete -f deploy/local/redis.yaml
      lsof -t -i:6379 | xargs kill -9 ;;

    cauldron)
      info "✋ Stopping cauldron"
      dd ;;

    dash-phenoapp-v2)
      info "✋ Stopping observability stack"
      dd ;;

    genie)
      info "✋ Stopping genie"
      dd ;;

    platelet-ui)
      info "✋ Stopping cauldron, genie, skurge, platelet and platelet-ui"
      cauldron && dd
      genie && dd
      pl && dd
      skurge && dd
      plu && dd ;;

    skurge)
      dd ;;

    spade-flows)
      ./bin/dev/stop.sh ;;

    *)
      error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}