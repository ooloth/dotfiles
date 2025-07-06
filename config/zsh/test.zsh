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
}

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/test.zsh" 2>/dev/null
fi
