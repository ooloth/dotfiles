run() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    advent-of-code)
      ./bin/run "$@" ;;

    *)
      error "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/run.zsh" 2>/dev/null
fi
