check() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "$DOTFILES/zsh/config/work/check.zsh" 2>/dev/null
fi
