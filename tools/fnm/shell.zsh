
########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

alias nvm="fnm"

###############
# COMPLETIONS #
###############

# See: https://github.com/Schniz/fnm/blob/master/docs/configuration.md
if have fnm; then
  eval "$(fnm env --use-on-cd --shell zsh --corepack-enabled --log-level=error)"
fi

