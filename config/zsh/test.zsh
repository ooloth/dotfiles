test() {
  local current_directory=$(basename $PWD)
  local args=""

  if [ "$#" -gt 0 ]; then
    args=" $@"
  fi

  case $current_directory in
    dash-phenoapp-v2)
      info "🧪 Running: pytest$args"
      pytest phenoapp "$@" ;;

    react-app)
      info "🧪 Running: vitest$args"
      npm run test "$@" ;;

    *)
      error "🚨 No 'test' case defined for '/$current_directory'" ;;
  esac
}