run() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    spade-flows)
      ./bin/dev/run.sh "$@" ;;

    *)
      error "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}
