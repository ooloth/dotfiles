########################
# ENVIRONMENT VARIABLES #
########################

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

if have op; then
  eval "$(op completion zsh)"; compdef _op op
fi
