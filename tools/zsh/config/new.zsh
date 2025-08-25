new() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    advent-of-code)
      ./bin/new "$@"
      ;;
    *)
      error "🚨 No 'new' case defined for '/${CURRENT_DIRECTORY}'"
      ;;
  esac
}

if is_work; then
  source "${DOTFILES}/tools/zsh/config/work/new.zsh" 2>/dev/null
fi
