start() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "${DOTFILES}/tools/zsh/config/work/start.zsh" 2>/dev/null
fi
