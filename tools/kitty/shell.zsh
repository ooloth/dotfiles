source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have kitten; then
  diff() {
    # see: https://sw.kovidgoyal.net/kitty/kittens/diff/
    kitten diff "$1" "$2";
  }
fi

