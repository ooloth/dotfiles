source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have kitten; then
  diff() { kitten diff "${1}" "${2}"; } # see: https://sw.kovidgoyal.net/kitty/kittens/diff/
  image() { kitten icat "$@"; } # see: https://sw.kovidgoyal.net/kitty/kittens/icat/
  s() { kitten ssh "$@"; } # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
fi

