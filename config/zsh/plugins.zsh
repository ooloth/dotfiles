# Initialize zsh completion before invoking plugin-specific completions below
# See: https://stackoverflow.com/questions/66338988/complete13-command-not-found-compde
autoload -Uz compinit && compinit

# docker
fpath=(/Users/michael.uloth/.docker/completions $fpath)

# fnm
eval "$(fnm env --use-on-cd --log-level=error)"

# fzf
eval "$(fzf --zsh)"

# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
source "$DOTFILES/config/zsh/p10k.zsh" # to customize, run `p10k configure` or edit config/zsh/p10k.zsh

# uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# zoxide
eval "$(zoxide init zsh)"

# zsh-autosuggestions
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting
source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/plugins.zsh" 2>/dev/null
fi
