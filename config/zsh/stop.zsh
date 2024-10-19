stop() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/stop.zsh"
fi