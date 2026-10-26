
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
  cached_completion uv uv generate-shell-completion zsh
  cached_completion uvx uvx --generate-shell-completion zsh
fi

