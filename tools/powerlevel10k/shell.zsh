
########################
# ENVIROMENT VARIABLES #
########################

# Powerlevel10k
export POWERLEVEL9K_CONFIG_FILE="${HOME}/.config/powerlevel10k/p10k.zsh"

###########
# ALIASES #
###########

alias powerlevel10k="p10k"

###############
# COMPLETIONS #
###############

# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
if have brew; then
  source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
  source "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" # to customize, run `p10k configure` or edit zsh/config/p10k.zsh
fi

