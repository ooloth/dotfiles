source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

if have fzf; then
  eval "$(fzf --zsh)"
fi

