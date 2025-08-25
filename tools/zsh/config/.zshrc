# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n] confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/macos/shell/aliases.zsh" # sets is_air, is_mini, is_work
source "${DOTFILES}/tools/zsh/utils.zsh" # sets have, info, warn, error

# NOTE: zshenv loads PATH + env vars and this file loads the rest
source "${DOTFILES}/tools/zsh/config/variables.zsh"
source "${DOTFILES}/tools/zsh/config/aliases.zsh"
source "${DOTFILES}/tools/zsh/config/options.zsh"
source "${DOTFILES}/tools/zsh/config/hooks.zsh"
source "${DOTFILES}/tools/zsh/config/plugins.zsh" # source last
