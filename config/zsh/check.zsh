check() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    dash-phenoapp-v2)
      info "Formatting, linting and type-checking"
      echo "TODO" ;;

    react-app)
      info "Formatting, linting and type-checking"
      echo "TODO" ;;

    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}