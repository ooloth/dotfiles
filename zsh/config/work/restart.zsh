restart() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    spade-flows)
      ./bin/dev/restart.sh "$@" ;;

    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}
