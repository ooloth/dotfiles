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

if have uv; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

