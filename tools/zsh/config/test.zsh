test() {
  local args=""
  local current_dir=$(basename $PWD)
  local error_msg="🚨 No 'test' case defined for '/${current_dir}'"

  if [ "$#" -gt 0 ]; then
    args=" $@"
  fi

  if is_work; then
    case "${current_dir}" in
      mapapp-1|mapapp-2|mapapp-3)
        ./bin/test.sh "$@" ;;

      react-app)
        info "🧪 Running: vitest$args"
        npm run test "$@" ;;

      spade-flows)
        ./bin/dev/test.sh "$@" ;;

      *)
        error "${error_msg}" ;;
    esac
  else
    case "${current_dir}" in
      advent-of-code)
        bin/test "$@" ;;

      dotfiles)
        ./test/run-tests.zsh "$@" ;;

      hub)
        PYTHONPATH=. pytest "$@" ;;

      scripts)
        PYTHONPATH=. pytest "$@" ;;

      *)
        error "${error_msg}" ;;
    esac
  fi
}

