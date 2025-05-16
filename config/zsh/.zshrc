# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# NOTE: zshenv loads PATH + env vars and this file loads the rest
source $HOME/.config/zsh/utils.zsh # source first (used by other files)
source $HOME/.config/zsh/variables.zsh
source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/options.zsh
source $HOME/.config/zsh/hooks.zsh
source $HOME/.config/zsh/plugins.zsh # source last
