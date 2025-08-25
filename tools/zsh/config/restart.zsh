restart() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'restart' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "${DOTFILES}/tools/zsh/config/work/restart.zsh" 2>/dev/null
fi
