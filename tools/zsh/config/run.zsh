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
  source "${DOTFILES}/tools/zsh/config/work/run.zsh" 2>/dev/null
fi
