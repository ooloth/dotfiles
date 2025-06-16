test() {
  local current_directory=$(basename $PWD)
  local args=""

  if [ "$#" -gt 0 ]; then
    args=" $@"
  fi

  case $current_directory in
    dash-phenoapp-v2)
      ./bin/test.sh "$@" ;;

    react-app)
      info "🧪 Running: vitest$args"
      npm run test "$@" ;;

    spade-app)
      ./bin/test.sh "$@" ;;

    spade-flows)
      ./bin/dev/test.sh "$@" ;;

    *)
      error "🚨 No 'test' case defined for '/$current_directory'" ;;
  esac
}
