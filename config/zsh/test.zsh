test() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    dash-phenoapp-v2)
      info "Running pytest"
      echo "TODO"

    react-app)
      info "Running vitest"
      echo "TODO"

    *)
      error "🚨 No 'test' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}