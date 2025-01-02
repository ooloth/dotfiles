# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# NOTE: zshenv loads env vars, zprofile loads PATH, and zshrc loads the rest
source $HOME/.config/zsh/utils.zsh # source first (used by other files)
source $HOME/.config/zsh/variables.zsh
source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/options.zsh
source $HOME/.config/zsh/hooks.zsh
source $HOME/.config/zsh/plugins.zsh # source last

# When opening a new terminal in kitty (not VS Code), if tmux isn't
# already active, attach to or restore the previous tmux session.
# if [ -z "$TMUX" ] && [ "$TERM" = "xterm-kitty" ]; then
#   t
# fi
