
########################
# ENVIRONMENT VARIABLES #
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

