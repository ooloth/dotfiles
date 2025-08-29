new() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    advent-of-code)
      ./bin/new "$@"
      ;;
    *)
      error "🚨 No 'new' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
  esac
}

