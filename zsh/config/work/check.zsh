check() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    dash-phenoapp-v2)
      ./bin/check.sh "$@" ;;

    react-app)
      info "Formatting, linting and type-checking"
      npm run lint ;;

    spade-app)
      ./bin/check.sh "$@" ;;

    spade-flows)
      ./bin/dev/check.sh "$@" ;;

    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}
