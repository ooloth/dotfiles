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
  rg() {
    # No kitten needed, but flag value will only work in kitty
    # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
    # see: https://github.com/BurntSushi/ripgrep/discussions/2611#discussioncomment-7110198
    rg --hyperlink-format=kitty "$@";
  }
  s() { kitten ssh "$@"; } # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
  transfer() { kitten transfer "$@"; } # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
fi

