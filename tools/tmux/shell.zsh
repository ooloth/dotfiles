source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have tmux; then
  alias t="tmux attach || exec tmux"
fi

