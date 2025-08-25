submit() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    advent-of-code)
      bin/submit "$@" ;;
    *)
      error "🚨 No 'submit' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}

if $IS_WORK; then
  source "${DOTFILES}/tools/zsh/config/work/submit.zsh" 2>/dev/null
fi
