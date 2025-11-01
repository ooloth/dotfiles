source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have kubectl; then
  alias k="kubectl"
  alias kc="k create"
  alias kcd="k create deployment"
  alias kd="k describe"
  alias ke="k expose"
  alias kg="k get"
  alias kgw="kg -o wide"
  alias kgy="kg -o yaml"
  alias ka="kg all"
  alias kr="k run"
  alias ks="k scale"
fi

###############
# COMPLETIONS #
###############

