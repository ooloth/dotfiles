check() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    *)
      error "🚨 No 'check' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if is_work; then
  source "${DOTFILES}/tools/zsh/config/work/check.zsh" 2>/dev/null
fi
