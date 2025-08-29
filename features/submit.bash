submit() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    advent-of-code)
      bin/submit "$@" ;;
    *)
      error "🚨 No 'submit' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}
