# fnm
eval "$(fnm env --use-on-cd --log-level=error)"

# fzf
export PATH="$PATH:/opt/homebrew/opt/fzf/bin"
eval "$(fzf --zsh)"

# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
source "$HOME/.config/zsh/p10k.zsh" # to customize, run `p10k configure` or edit config/zsh/p10k.zsh

# zsh-autosuggestions
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting
source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/plugins.zsh"
fi
