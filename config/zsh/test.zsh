test() {
  local current_directory=$(basename $PWD)
  local args=""

  if [ "$#" -gt 0 ]; then
    args=" $@"
  fi

  case $current_directory in
    *)
      error "🚨 No 'test' case defined for '/$current_directory'" ;;
  esac
}

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/test.zsh"
fi