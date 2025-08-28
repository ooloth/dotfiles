test() {
  local current_directory=$(basename $PWD)
  local args=""

  if [ "$#" -gt 0 ]; then
    args=" $@"
  fi

  case $current_directory in
    advent-of-code)
      bin/test "$@"
      ;;
    dotfiles)
      ./test/run-tests.zsh "$@"
      ;;
    hub)
      PYTHONPATH=. pytest "$@"
      ;;
    scripts)
      PYTHONPATH=. pytest "$@"
      ;;
    *)
      error "🚨 No 'test' case defined for '/$current_directory'"
      ;;
  esac

  if is_work; then
    case $current_directory in
      mapapp)
        ./bin/test.sh "$@" ;;

      mapapp-1)
        ./bin/test.sh "$@" ;;

      mapapp-2)
        ./bin/test.sh "$@" ;;

      mapapp-3)
        ./bin/test.sh "$@" ;;

      react-app)
        info "🧪 Running: vitest$args"
        npm run test "$@" ;;

      spade-flows)
        ./bin/dev/test.sh "$@" ;;

      *)
        error "🚨 No 'test' case defined for '/$current_directory'" ;;
    esac
  fi
}

