test() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    dash-phenoapp-v2)
      info "Running pytest"
      pytest phenoapp

    react-app)
      info "Running vitest"
      npm run test "$@"

    *)
      error "🚨 No 'test' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}