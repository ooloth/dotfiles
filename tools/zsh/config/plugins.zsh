#!/usr/bin/env zsh
# set -euo pipefail

##########
# PROMPT #
##########

# fnm
eval "$(fnm env --use-on-cd --log-level=error)"

# FIXME: crashes terminal if set -e is enabled
# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
source "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" # to customize, run `p10k configure` or edit zsh/config/p10k.zsh

###############
# COMPLETIONS #
###############

# Must come before compinit to support rust tab completions
# See: https://rust-lang.github.io/rustup/installation/index.html
fpath+=~/.zfunc

# Initialize zsh completion before invoking plugin-specific completions below
# See: https://stackoverflow.com/questions/66338988/complete13-command-not-found-compde
autoload -Uz compinit && compinit

# docker
fpath=(/Users/michael.uloth/.docker/completions $fpath)

# fzf
eval "$(fzf --zsh)"

# uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# zoxide
eval "$(zoxide init zsh)"

# zsh-autosuggestions
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting
source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if is_work; then
  source "${DOTFILES}/tools/zsh/config/work/plugins.zsh" 2>/dev/null
fi

