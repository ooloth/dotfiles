source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
export HOMEBREW_NO_AUTO_UPDATE=1      # I'll update manually (don't slow down individual install/upgrade commands)
export HOMEBREW_NO_INSTALL_CLEANUP=1  # I'll clean up manually (don't slow down individual install/upgrade commands)
export HOMEBREW_UPGRADE_GREEDY=1      # Upgrade casks with auto-updates: true or version: latest as well

if have brew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

# TODO: try enabling if completions for brew-installed tools aren't working
# See: https://github.com/eza-community/eza/blob/main/INSTALL.md#for-zsh-with-homebrew
# if have brew; then
#     FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
# fi

