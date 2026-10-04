# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n] confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work, info, etc
source "${DOTFILES}/tools/zsh/config/core.zsh" # env, history, completions, aliases
source "${DOTFILES}/tools/zsh/config/hooks.zsh" # python venv activation
source "${DOTFILES}/tools/zsh/config/tools.zsh" # tool-specific configs via manifest

# Claude Code copies this shell's aliases and functions into the shell its agents run commands in.
# Remove every alias, and every function named like a builtin or a command (test, ls, kill, env, ...),
# so a standard name always means the standard command there. Checked by `dcheck`.
if [[ -n "${CLAUDECODE:-}" ]]; then
  unalias -m '*'
  for f in ${(k)functions}; do (( $+builtins[$f] || $+commands[$f] )) && unfunction "$f"; done
  unset f
fi
